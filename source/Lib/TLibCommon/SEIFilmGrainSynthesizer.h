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

/**
 \file     SEIFilmGrainSynthesizer.h
 \brief    SMPTE RDD5 based film grain synthesis functionality from SEI messages
 */

#ifndef __SEIFILMGRAINSYNTHESIZER__
#define __SEIFILMGRAINSYNTHESIZER__

#include "SEI.h"
#include "TComPicYuv.h"

//#if _MSC_VER > 1000
//#pragma once
//#endif // _MSC_VER > 1000

//! \ingroup CommonLib
//! \{

#define MAX_ALLOWED_MODEL_VALUES 3
#define MIN_LOG2SCALE_VALUE 2
#define MAX_LOG2SCALE_VALUE 7
#define FILM_GRAIN_MODEL_ID_VALUE 0
#define BLENDING_MODE_VALUE 0
#define MAX_STANDARD_DEVIATION 255
#define MIN_CUT_OFF_FREQUENCY 2
#define MAX_CUT_OFF_FREQUENCY 14
#define DEFAULT_HORZ_CUT_OFF_FREQUENCY 8
#define MAX_ALLOWED_COMP_MODEL_PAIRS 10

#define SCALE_DOWN_422  181 /* in Q-format of 8 : 1/sqrt(2) */
#define Q_FORMAT_SCALING 8
#define GRAIN_SCALE 6
#define MIN_CHROMA_FORMAT_IDC 0
#define MAX_CHROMA_FORMAT_IDC 3
#define MIN_BIT_DEPTH 8
#define MAX_BIT_DEPTH 16
#define BIT_DEPTH_8 8
#define NUM_8x8_BLKS_16x16 4
#define BLK_8 8
#define BLK_16 16
#define INTENSITY_INTERVAL_MATCH_FAIL -1
#define COLOUR_OFFSET_LUMA 0
#define COLOUR_OFFSET_CR 85
#define COLOUR_OFFSET_CB 170

#define NUM_CUT_OFF_FREQ 13
#define DATA_BASE_SIZE 64

#define MIN_WIDTH 128
#define MAX_WIDTH 7680
#define MIN_HEIGHT 128
#define MAX_HEIGHT 4320

#define MIN_CHROMA_FORMAT_IDC 0
#define MAX_CHROMA_FORMAT_IDC 3
#define MIN_BIT_DEPTH 8
#define MAX_BIT_DEPTH 16
#define BIT_DEPTH_8 8
#define NUM_8x8_BLKS_16x16 4
#define BLK_8 8
#define BLK_16 16
#define INTENSITY_INTERVAL_MATCH_FAIL -1
#define COLOUR_OFFSET_LUMA 0
#define COLOUR_OFFSET_CR 85
#define COLOUR_OFFSET_CB 170

#define CLIP3(min, max, x) (((x) > (max)) ? (max) :(((x) < (min))? (min):(x)))
#define MIN(x,y) (((x) > (y)) ? (y) : (x))
#define MSB16(x) ((x&0xFFFF0000)>>16)
#define LSB16(x) (x&0x0000FFFF)
#define BIT0(x) (x&0x1)
#define POS_30 (1<<30)
#define POS_2 (1<<2)

/* Error start codes for various classes of errors */
#define FGS_FILE_IO_ERROR    0x0010
#define FGS_PARAM_ERROR      0x0020

/* Error codes for various errors in SMPTE-RDD5 standalone grain synthesizer */
typedef enum
{
  /* No error */
  FGS_SUCCESS = 0,
  /* Invalid input width */
  FGS_INVALID_WIDTH = FGS_FILE_IO_ERROR + 0x01,
  /* Invalid input height */
  FGS_INVALID_HEIGHT = FGS_FILE_IO_ERROR + 0x02,
  /* Invalid Chroma format idc */
  FGS_INVALID_CHROMA_FORMAT = FGS_FILE_IO_ERROR + 0x03,
  /* Invalid bit depth */
  FGS_INVALID_BIT_DEPTH = FGS_FILE_IO_ERROR + 0x04,

  /* Invalid Film grain characteristic cancel flag */
  FGS_INVALID_FGC_CANCEL_FLAG = FGS_PARAM_ERROR + 0x01,
  /* Invalid film grain model id */
  FGS_INVALID_GRAIN_MODEL_ID = FGS_PARAM_ERROR + 0x02,
  /* Invalid separate color description present flag */
  FGS_INVALID_SEP_COL_DES_FLAG = FGS_PARAM_ERROR + 0x03,
  /* Invalid blending mode */
  FGS_INVALID_BLEND_MODE = FGS_PARAM_ERROR + 0x04,
  /* Invalid log_2_scale_factor value */
  FGS_INVALID_LOG2_SCALE_FACTOR = FGS_PARAM_ERROR + 0x05,
  /* Invalid component model present flag */
  FGS_INVALID_COMP_MODEL_PRESENT_FLAG = FGS_PARAM_ERROR + 0x06,
  /* Invalid number of model values */
  FGS_INVALID_NUM_MODEL_VALUES = FGS_PARAM_ERROR + 0x07,
  /* Invalid bound values, overlapping boundaries */
  FGS_INVALID_INTENSITY_BOUNDARY_VALUES = FGS_PARAM_ERROR + 0x08,
  /* Invalid standard deviation */
  FGS_INVALID_STANDARD_DEVIATION = FGS_PARAM_ERROR + 0x09,
  /* Invalid cut off frequencies */
  FGS_INVALID_CUT_OFF_FREQUENCIES = FGS_PARAM_ERROR + 0x0A,
  /* Invalid number of cut off frequency pairs */
  FGS_INVALID_NUM_CUT_OFF_FREQ_PAIRS = FGS_PARAM_ERROR + 0x0B,
  /* Invalid film grain characteristics repetition period */
  FGS_INVALID_FGC_REPETETION_PERIOD = FGS_PARAM_ERROR + 0x0C,

  /* Failure error code */
  FGS_FAIL = 0xFF
}FGS_ERROR_T;
/* FGC Error Codes END */

typedef struct GrainSynthesisStruct_t
{
  int8_t dataBase[NUM_CUT_OFF_FREQ][NUM_CUT_OFF_FREQ][DATA_BASE_SIZE][DATA_BASE_SIZE];
  int16_t intensityInterval[MAX_NUM_COMPONENT][MAX_NUM_INTENSITIES];
}GrainSynthesisStruct;

class SEIFilmGrainSynthesizer
{

private:
  uint32_t                     m_width;
  uint32_t                     m_height;
  ChromaFormat                 m_chromaFormat;
  uint8_t                      m_bitDepth;
  uint32_t                     m_idrPicId;
  uint8_t                      m_enableDeblocking;

  GrainSynthesisStruct        *m_pGrainSynt;
public:  
  uint32_t                     m_poc;
  uint32_t                     m_errorCode;
  SEIFilmGrainCharacteristics *m_pFgcParameters;

public:
  SEIFilmGrainSynthesizer();
  void create(uint32_t width, uint32_t height, ChromaFormat fmt, uint8_t bitDepth,
    uint32_t idrPicId, uint8_t enableDeblocking);

  virtual ~SEIFilmGrainSynthesizer();

  void      fgsInit();
  void      fgsDeinit();
  void      grainSynthesizeAndBlend(TComPicYuv* pGrainBuf, Bool isIdrPic);
  uint8_t   grainValidateParams();

private:
  void      dataBaseGen();
  uint32_t prng(uint32_t x_r);
  Pel blockAverage(Pel *decSampleBlk8,
    uint32_t widthComp,
    uint16_t *pNumSamples,
    uint8_t ySize,
    uint8_t xSize,
    uint8_t bitDepth);
  void deblockGrainStripe(int32_t *grainStripe, uint32_t widthComp, uint32_t strideComp);
  void blendStripe(Pel *decSampleOffsetY, int32_t *grainStripe,
    uint32_t widthComp, uint32_t blockHeight, uint8_t bitDepth);
  void simulateGrainBlk8x8(int32_t *grainStripe, uint32_t grainStripeOffsetBlk8,
    GrainSynthesisStruct *pGrainSynt, uint32_t width, uint8_t log2ScaleFactor,
    int16_t scaleFactor, uint32_t kOffset, uint32_t lOffset,
    uint8_t h, uint8_t v, uint32_t xSize);

};// END CLASS DEFINITION SEIFilmGrainSynthesizer

#endif