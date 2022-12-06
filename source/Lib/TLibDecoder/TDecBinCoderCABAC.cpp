/* The copyright in this software is being made available under the BSD
 * License, included below. This software may be subject to other third party
 * and contributor rights, including patent rights, and no such rights are
 * granted under this license.
 *
 * Copyright (c) 2010-2022, ITU/ISO/IEC
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *  * Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 *  * Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *  * Neither the name of the ITU/ISO/IEC nor the names of its contributors may
 *    be used to endorse or promote products derived from this software without
 *    specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
 */

/** \file     TDecBinCoderCABAC.cpp
    \brief    binary entropy decoder of CABAC
*/

#include "TDecBinCoderCABAC.h"
#include "TLibCommon/Debug.h"
#if RExt__DECODER_DEBUG_BIT_STATISTICS
#include "TLibCommon/TComCodingStatistics.h"
#endif

//! \ingroup TLibDecoder
//! \{

TDecBinCABAC::TDecBinCABAC()
: m_pcTComBitstream( 0 )
{
}

TDecBinCABAC::~TDecBinCABAC()
{
}

Void
TDecBinCABAC::init( TComInputBitstream* pcTComBitstream )
{
  m_pcTComBitstream = pcTComBitstream;
}

Void
TDecBinCABAC::uninit()
{
  m_pcTComBitstream = 0;
}

Void
TDecBinCABAC::start()
{
  assert( m_pcTComBitstream->getNumBitsUntilByteAligned() == 0 );
#if RExt__DECODER_DEBUG_BIT_STATISTICS
  TComCodingStatistics::UpdateCABACStat(STATS__CABAC_INITIALISATION, 512, 510, 0);
#endif
  m_uiRange    = 510;
  m_bitsNeeded = -8;
  m_uiValue    = (m_pcTComBitstream->readByte() << 8);
  m_uiValue   |= m_pcTComBitstream->readByte();
}

Void
TDecBinCABAC::finish()
{
  UInt lastByte;

  m_pcTComBitstream->peekPreviousByte( lastByte );
  // Check for proper stop/alignment pattern
  assert( ((lastByte << (8 + m_bitsNeeded)) & 0xff) == 0x80 );
}

/**
 - Copy CABAC state.
 .
 \param pcTDecBinIf The source CABAC engine.
 */
Void
TDecBinCABAC::copyState( const TDecBinIf* pcTDecBinIf )
{
  const TDecBinCABAC* pcTDecBinCABAC = pcTDecBinIf->getTDecBinCABAC();
  m_uiRange   = pcTDecBinCABAC->m_uiRange;
  m_uiValue   = pcTDecBinCABAC->m_uiValue;
  m_bitsNeeded= pcTDecBinCABAC->m_bitsNeeded;
}



#if RExt__DECODER_DEBUG_BIT_STATISTICS
Void TDecBinCABAC::decodeBin( UInt& ruiBin, ContextModel &rcCtxModel, const TComCodingStatisticsClassType &whichStat )
#elif defined(HWDUMP_CABAC)
Void TDecBinCABAC::decodeBin( UInt& ruiBin, ContextModel &rcCtxModel, const char* model_name, UInt ctx_idx )
#else
Void TDecBinCABAC::decodeBin( UInt& ruiBin, ContextModel &rcCtxModel )
#endif
{
#if DEBUG_CABAC_BINS
  const UInt startingRange = m_uiRange;
#endif

#ifdef HWDUMP_CABAC
  //"(model_name, ctx_idx, EP_mode_flag), [prev_state, m_uiRange, m_uiValue, uiLPS, read_byte_flag, read_byte], new_state, m_uiRange, m_uiValue, mps_h_lps_l, ruiLen, ruiBin\n"
  FILE *fp;
  fp=fopen("test_vector/test_vector_cabac.txt", "a");
#endif

  UInt uiLPS = TComCABACTables::sm_aucLPSTable[ rcCtxModel.getState() ][ ( m_uiRange >> 6 ) - 4 ];
  m_uiRange -= uiLPS;
  UInt scaledRange = m_uiRange << 7;

#ifdef HWDUMP_CABAC
  fprintf(fp, "(%s, %d, 0), [%d, %d, %d, %d, ", model_name, ctx_idx, rcCtxModel.getState(), m_uiRange+uiLPS, m_uiValue, uiLPS);
#endif

  if( m_uiValue < scaledRange )
  {
    // MPS path
    ruiBin = rcCtxModel.getMps();
#if RExt__DECODER_DEBUG_BIT_STATISTICS
    TComCodingStatistics::UpdateCABACStat(whichStat, m_uiRange+uiLPS, m_uiRange, Int(ruiBin));
#endif
    rcCtxModel.updateMPS();

    if ( scaledRange < ( 256 << 7 ) )
    {
      m_uiRange = scaledRange >> 6;
      m_uiValue += m_uiValue;

      if ( ++m_bitsNeeded == 0 )
      {
#ifdef HWDUMP_CABAC
        UInt tmpReadByte;
        m_bitsNeeded = -8;
        tmpReadByte = m_pcTComBitstream->readByte();
        m_uiValue += tmpReadByte;
        fprintf(fp, "1, %02x], %d, %d, %d, 1, 1, %d\n", tmpReadByte, rcCtxModel.getState(), m_uiRange, m_uiValue, ruiBin);
      }
      else {
        fprintf(fp, "0, 00], %d, %d, %d, 1, 1, %d\n", rcCtxModel.getState(), m_uiRange, m_uiValue, ruiBin);
      }
#else
        m_bitsNeeded = -8;
        m_uiValue += m_pcTComBitstream->readByte();
      }
#endif
    }
#ifdef HWDUMP_CABAC
    else {
      fprintf(fp, "0, 00], %d, %d, %d, 1, 1, %d\n", rcCtxModel.getState(), m_uiRange, m_uiValue, ruiBin);
    }
#endif
  }
  else
  {
    // LPS path
    ruiBin      = 1 - rcCtxModel.getMps();
#if RExt__DECODER_DEBUG_BIT_STATISTICS
    TComCodingStatistics::UpdateCABACStat(whichStat, m_uiRange+uiLPS, uiLPS, Int(ruiBin));
#endif
    Int numBits = TComCABACTables::sm_aucRenormTable[ uiLPS >> 3 ];
    m_uiValue   = ( m_uiValue - scaledRange ) << numBits;
    m_uiRange   = uiLPS << numBits;
    rcCtxModel.updateLPS();

    m_bitsNeeded += numBits;

    if ( m_bitsNeeded >= 0 )
    {
#ifdef HWDUMP_CABAC
      UInt tmpReadByte;
      tmpReadByte = m_pcTComBitstream->readByte();
      m_uiValue += tmpReadByte << m_bitsNeeded;
      m_bitsNeeded -= 8;
      fprintf(fp, "1, %02x], %d, %d, %d, 0, 1, %d\n", tmpReadByte, rcCtxModel.getState(), m_uiRange, m_uiValue, ruiBin);
    }
    else {
      fprintf(fp, "0, 00], %d, %d, %d, 0, 1, %d\n", rcCtxModel.getState(), m_uiRange, m_uiValue, ruiBin);
    }
#else
      m_uiValue += m_pcTComBitstream->readByte() << m_bitsNeeded;
      m_bitsNeeded -= 8;
    }
#endif
  }
#ifdef HWDUMP_CABAC
  fclose(fp);
#endif

#if DEBUG_CABAC_BINS
  if ((g_debugCounter + debugCabacBinWindow) >= debugCabacBinTargetLine)
  {
    std::cout << g_debugCounter << ": coding bin value " << ruiBin << ", range = [" << startingRange << "->" << m_uiRange << "]\n";
  }

  if (g_debugCounter >= debugCabacBinTargetLine)
  {
    UChar breakPointThis;
    breakPointThis = 7;
  }
  if (g_debugCounter >= (debugCabacBinTargetLine + debugCabacBinWindow))
  {
    exit(0);
  }
  g_debugCounter++;
#endif
}


#if RExt__DECODER_DEBUG_BIT_STATISTICS
Void TDecBinCABAC::decodeBinEP( UInt& ruiBin, const TComCodingStatisticsClassType &whichStat )
#elif defined(HWDUMP_CABAC)
Void TDecBinCABAC::decodeBinEP( UInt& ruiBin, const char* model_name, UInt ctx_idx )
#else
Void TDecBinCABAC::decodeBinEP( UInt& ruiBin )
#endif
{

#ifdef HWDUMP_CABAC
  //"(model_name, ctx_idx, EP_mode_flag), [prev_state, m_uiRange, m_uiValue, uiLPS, read_byte_flag, read_byte], new_state, m_uiRange, m_uiValue, mps_h_lps_l, ruiLen, ruiBin\n"
  FILE *fp;
  fp=fopen("test_vector/test_vector_cabac.txt", "a");
  fprintf(fp, "(%s, %d, 1), [32, %d, %d, 0, ", model_name, ctx_idx, m_uiRange, m_uiValue);
#endif

  if (m_uiRange == 256)
  {
#if RExt__DECODER_DEBUG_BIT_STATISTICS
    decodeAlignedBinsEP(ruiBin, 1, whichStat);
#elif defined(HWDUMP_CABAC)
    decodeAlignedBinsEP(ruiBin, 1, model_name, ctx_idx);
#else
    decodeAlignedBinsEP(ruiBin, 1);
#endif
    return;
  }

  m_uiValue += m_uiValue;

  if ( ++m_bitsNeeded >= 0 )
  {
#ifdef HWDUMP_CABAC
    UInt tempReadByte;
    m_bitsNeeded = -8;
    tempReadByte = m_pcTComBitstream->readByte();
    m_uiValue += tempReadByte;
    fprintf(fp, "1, %02x], ", tempReadByte);
  }
  else {
    fprintf(fp, "0, 00], ");
  }
#else
    m_bitsNeeded = -8;
    m_uiValue += m_pcTComBitstream->readByte();
  }
#endif

  ruiBin = 0;
  UInt scaledRange = m_uiRange << 7;
  if ( m_uiValue >= scaledRange )
  {
    ruiBin = 1;
    m_uiValue -= scaledRange;
  }

#ifdef HWDUMP_CABAC
  fprintf(fp, "32, %d, %d, 1, 1, %d\n", m_uiRange, m_uiValue, ruiBin);
  fclose(fp);
#endif

#if RExt__DECODER_DEBUG_BIT_STATISTICS
  TComCodingStatistics::IncrementStatisticEP(whichStat, 1, Int(ruiBin));
#endif
}

#if RExt__DECODER_DEBUG_BIT_STATISTICS
Void TDecBinCABAC::decodeBinsEP( UInt& ruiBin, Int numBins, const TComCodingStatisticsClassType &whichStat )
#elif defined(HWDUMP_CABAC)
Void TDecBinCABAC::decodeBinsEP( UInt& ruiBin, Int numBins, const char* model_name, UInt ctx_idx )
#else
Void TDecBinCABAC::decodeBinsEP( UInt& ruiBin, Int numBins )
#endif
{

#ifdef HWDUMP_CABAC
  //"(model_name, ctx_idx, EP_mode_flag), [prev_state, m_uiRange, m_uiValue, uiLPS, read_byte_flag, read_byte], new_state, m_uiRange, m_uiValue, mps_h_lps_l, ruiLen, ruiBin\n"
  FILE *fp;
  fp=fopen("test_vector/test_vector_cabac.txt", "a");
#endif

  if (m_uiRange == 256)
  {
#if RExt__DECODER_DEBUG_BIT_STATISTICS
    decodeAlignedBinsEP(ruiBin, numBins, whichStat);
#elif defined(HWDUMP_CABAC)
    decodeAlignedBinsEP(ruiBin, numBins, model_name, ctx_idx);
#else
    decodeAlignedBinsEP(ruiBin, numBins);
#endif
    return;
  }

  UInt bins = 0;
#if RExt__DECODER_DEBUG_BIT_STATISTICS
  Int origNumBins=numBins;
#endif
  while ( numBins > 8 )
  {
#ifdef HWDUMP_CABAC
    UInt tempReadByte;
    tempReadByte = m_pcTComBitstream->readByte();
    fprintf(fp, "(%s, %d, 1), [32, %d, %d, 0, 1, %02x], 32, %d, ", model_name, ctx_idx, m_uiRange, m_uiValue, tempReadByte, m_uiRange);
    m_uiValue = ( m_uiValue << 8 ) + ( tempReadByte << ( 8 + m_bitsNeeded ) );
#else
    m_uiValue = ( m_uiValue << 8 ) + ( m_pcTComBitstream->readByte() << ( 8 + m_bitsNeeded ) );
#endif

    UInt scaledRange = m_uiRange << 15;
    for ( Int i = 0; i < 8; i++ )
    {
      bins += bins;
      scaledRange >>= 1;
      if ( m_uiValue >= scaledRange )
      {
        bins++;
        m_uiValue -= scaledRange;
      }
    }
    numBins -= 8;
#ifdef HWDUMP_CABAC
    fprintf(fp, "%d, 1, %d, %d\n", m_uiValue, 8, bins);
#endif
  }

#ifdef HWDUMP_CABAC
  fprintf(fp, "(%s, %d, 1), [32, %d, %d, 0, ", model_name, ctx_idx, m_uiRange, m_uiValue);
#endif

  m_bitsNeeded += numBins;
  m_uiValue <<= numBins;

  if ( m_bitsNeeded >= 0 )
  {
#ifdef HWDUMP_CABAC
    UInt tempReadByte;
    tempReadByte = m_pcTComBitstream->readByte();
    m_uiValue += tempReadByte << m_bitsNeeded;
    m_bitsNeeded -= 8;
    fprintf(fp, "1, %02x], 32, %d, ", tempReadByte, m_uiRange);
  }
  else {
    fprintf(fp, "0, 00], 32, %d, ", m_uiRange);
  }
#else
    m_uiValue += m_pcTComBitstream->readByte() << m_bitsNeeded;
    m_bitsNeeded -= 8;
  }
#endif

  UInt scaledRange = m_uiRange << ( numBins + 7 );
  for ( Int i = 0; i < numBins; i++ )
  {
    bins += bins;
    scaledRange >>= 1;
    if ( m_uiValue >= scaledRange )
    {
      bins++;
      m_uiValue -= scaledRange;
    }
  }

#ifdef HWDUMP_CABAC
    fprintf(fp, "%d, 1, %d, %d\n", m_uiValue, numBins, bins);
#endif

  ruiBin = bins;

#ifdef HWDUMP_CABAC
  fclose(fp);
#endif

#if RExt__DECODER_DEBUG_BIT_STATISTICS
  TComCodingStatistics::IncrementStatisticEP(whichStat, origNumBins, Int(ruiBin));
#endif
}

Void TDecBinCABAC::align()
{
#if RExt__DECODER_DEBUG_BIT_STATISTICS
  TComCodingStatistics::UpdateCABACStat(STATS__CABAC_EP_BIT_ALIGNMENT, m_uiRange, 256, 0);
#endif
  m_uiRange = 256;
}

#if RExt__DECODER_DEBUG_BIT_STATISTICS
Void TDecBinCABAC::decodeAlignedBinsEP( UInt& ruiBins, Int numBins, const class TComCodingStatisticsClassType &whichStat )
#elif defined(HWDUMP_CABAC)
Void TDecBinCABAC::decodeAlignedBinsEP( UInt& ruiBins, Int numBins, const char* model_name, UInt ctx_idx )
#else
Void TDecBinCABAC::decodeAlignedBinsEP( UInt& ruiBins, Int numBins )
#endif
{
  Int binsRemaining = numBins;
  ruiBins = 0;

#ifdef HWDUMP_CABAC
  //"(model_name, ctx_idx, EP_mode_flag), [prev_state, m_uiRange, m_uiValue, uiLPS, read_byte_flag, read_byte], new_state, m_uiRange, m_uiValue, mps_h_lps_l, ruiLen, ruiBin\n"
  FILE *fp;
  fp=fopen("test_vector/test_vector_cabac.txt", "a");
#endif

  assert(m_uiRange == 256); //aligned decode only works when range = 256

  while (binsRemaining > 0)
  {
    const UInt binsToRead = std::min<UInt>(binsRemaining, 8); //read bytes if able to take advantage of the system's byte-read function
    const UInt binMask    = (1 << binsToRead) - 1;

    //The MSB of m_uiValue is known to be 0 because range is 256. Therefore:
    // > The comparison against the symbol range of 128 is simply a test on the next-most-significant bit
    // > "Subtracting" the symbol range if the decoded bin is 1 simply involves clearing that bit.
    //
    //As a result, the required bins are simply the <binsToRead> next-most-significant bits of m_uiValue
    //(m_uiValue is stored MSB-aligned in a 16-bit buffer - hence the shift of 15)
    //
    //   m_uiValue = |0|V|V|V|V|V|V|V|V|B|B|B|B|B|B|B|        (V = usable bit, B = potential buffered bit (buffer refills when m_bitsNeeded >= 0))
    //
    const UInt newBins = (m_uiValue >> (15 - binsToRead)) & binMask;

#ifdef HWDUMP_CABAC
    fprintf(fp, "(%s, %d, 1), [32, %d, %d, 0, ", model_name, ctx_idx, m_uiRange, m_uiValue);
#endif

    ruiBins   = (ruiBins   << binsToRead) | newBins;
    m_uiValue = (m_uiValue << binsToRead) & 0x7FFF;

    binsRemaining -= binsToRead;
    m_bitsNeeded  += binsToRead;

    if (m_bitsNeeded >= 0)
    {
#ifdef HWDUMP_CABAC
      UInt tempReadByte;
      tempReadByte = m_pcTComBitstream->readByte();
      m_uiValue    |= tempReadByte << m_bitsNeeded;
      m_bitsNeeded -= 8;
      fprintf(fp, "1, %02x], 32, %d, %d, 1, %d, %d\n", tempReadByte, m_uiRange, m_uiValue, binsToRead, newBins);
    }
    else {
      fprintf(fp, "0, 00], 32, %d, %d, 1, %d, %d\n", m_uiRange, m_uiValue, binsToRead, newBins);
    }
#else
      m_uiValue    |= m_pcTComBitstream->readByte() << m_bitsNeeded;
      m_bitsNeeded -= 8;
    }
#endif
  }

#ifdef HWDUMP_CABAC
  fclose(fp);
#endif

#if RExt__DECODER_DEBUG_BIT_STATISTICS
  TComCodingStatistics::IncrementStatisticEP(whichStat, numBins, Int(ruiBins));
#endif
}

#ifdef HWDUMP_CABAC
Void
TDecBinCABAC::decodeBinTrm( UInt& ruiBin, const char* model_name, UInt ctx_idx )
#else
Void
TDecBinCABAC::decodeBinTrm( UInt& ruiBin )
#endif
{

#ifdef HWDUMP_CABAC
    //"(model_name, ctx_idx, EP_mode_flag), [prev_state, m_uiRange, m_uiValue, uiLPS, read_byte_flag, read_byte], new_state, m_uiRange, m_uiValue, mps_h_lps_l, ruiLen, ruiBin\n"
  FILE *fp;
  fp=fopen("test_vector/test_vector_cabac.txt", "a");
  fprintf(fp, "(%s, %d, 1), [32, %d, %d, 0, ", model_name, ctx_idx, m_uiRange, m_uiValue);
#endif

  m_uiRange -= 2;
  UInt scaledRange = m_uiRange << 7;
  if( m_uiValue >= scaledRange )
  {
    ruiBin = 1;
#ifdef HWDUMP_CABAC
    fprintf(fp, "0, 00], 32, %d, %d, 1, 1, 1\n", m_uiRange, m_uiValue);
#endif
#if RExt__DECODER_DEBUG_BIT_STATISTICS
    TComCodingStatistics::UpdateCABACStat(STATS__CABAC_TRM_BITS, m_uiRange+2, 2, ruiBin);
    TComCodingStatistics::IncrementStatisticEP(STATS__BYTE_ALIGNMENT_BITS, -m_bitsNeeded, 0);
#endif
  }
  else
  {
    ruiBin = 0;
#if RExt__DECODER_DEBUG_BIT_STATISTICS
    TComCodingStatistics::UpdateCABACStat(STATS__CABAC_TRM_BITS, m_uiRange+2, m_uiRange, ruiBin);
#endif
    if ( scaledRange < ( 256 << 7 ) )
    {
      m_uiRange = scaledRange >> 6;
      m_uiValue += m_uiValue;

      if ( ++m_bitsNeeded == 0 )
      {
#ifdef HWDUMP_CABAC
        UInt tempReadByte;
        m_bitsNeeded = -8;
        tempReadByte = m_pcTComBitstream->readByte();
        m_uiValue += tempReadByte;
        fprintf(fp, "1, %02x], 32, %d, %d, 1, 1, 0\n", tempReadByte, m_uiRange, m_uiValue);
      }
      else {
        fprintf(fp, "0, 00], 32, %d, %d, 1, 1, 0\n", m_uiRange, m_uiValue);
      }
#else
        m_bitsNeeded = -8;
        m_uiValue += m_pcTComBitstream->readByte();
      }
#endif
    }
#ifdef HWDUMP_CABAC
    else {
      fprintf(fp, "0, 00], 32, %d, %d, 1, 1, 0\n", m_uiRange, m_uiValue);
    }
#endif
  }

#ifdef HWDUMP_CABAC
  fclose(fp);
#endif

}

/** Read a PCM code.
 * \param uiLength code bit-depth
 * \param ruiCode pointer to PCM code value
 * \returns Void
 */
Void  TDecBinCABAC::xReadPCMCode(UInt uiLength, UInt& ruiCode)
{
  assert ( uiLength > 0 );
  m_pcTComBitstream->read (uiLength, ruiCode);
#if RExt__DECODER_DEBUG_BIT_STATISTICS
  TComCodingStatistics::IncrementStatisticEP(STATS__CABAC_PCM_CODE_BITS, uiLength, ruiCode);
#endif
}
//! \}
