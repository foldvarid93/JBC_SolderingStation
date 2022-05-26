/*********************************************************************
*          Portions COPYRIGHT 2016 STMicroelectronics                *
*          Portions SEGGER Microcontroller GmbH & Co. KG             *
*        Solutions for real time microcontroller applications        *
**********************************************************************
*                                                                    *
*        (c) 1996 - 2015  SEGGER Microcontroller GmbH & Co. KG       *
*                                                                    *
*        Internet: www.segger.com    Support:  support@segger.com    *
*                                                                    *
**********************************************************************

** emWin V5.32 - Graphical user interface for embedded applications **
All  Intellectual Property rights  in the Software belongs to  SEGGER.
emWin is protected by  international copyright laws.  Knowledge of the
source code may not be used to write a similar product.  This file may
only be used in accordance with the following terms:

The  software has  been licensed  to STMicroelectronics International
N.V. a Dutch company with a Swiss branch and its headquarters in Plan-
les-Ouates, Geneva, 39 Chemin du Champ des Filles, Switzerland for the
purposes of creating libraries for ARM Cortex-M-based 32-bit microcon_
troller products commercialized by Licensee only, sublicensed and dis_
tributed under the terms and conditions of the End User License Agree_
ment supplied by STMicroelectronics International N.V.
Full source code is available at: www.segger.com

We appreciate your understanding and fairness.
----------------------------------------------------------------------
File        : LCDConf_FlexColor_Template.h
Purpose     : Display driver configuration file
---------------------------END-OF-HEADER------------------------------
*/

/**
  ******************************************************************************
  * @attention
  *
  * Licensed under MCD-ST Liberty SW License Agreement V2, (the "License");
  * You may not use this file except in compliance with the License.
  * You may obtain a copy of the License at:
  *
  *        http://www.st.com/software_license_agreement_liberty_v2
  *
  * Unless required by applicable law or agreed to in writing, software 
  * distributed under the License is distributed on an "AS IS" BASIS, 
  * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  * See the License for the specific language governing permissions and
  * limitations under the License.
  *
  ******************************************************************************
  */
#ifndef LCDCONF_H
#define LCDCONF_H

#include "GUI.h"
#include "stm32f4xx.h"
#include "LCD_Private.h"
#include "GUI_Private.h"
#include "LCD_ConfDefaults.h"
//
#define	LCD_DATA_PORT				GPIOB
#define	LCD_CONTROL_PORT			GPIOB
//Chip select
#define	LCD_CS_PORT					GPIOB
#define LCD_CS_PIN					GPIO_PIN_8
#define LCD_CS_H					0x00000100
#define LCD_CS_L					0x01000000
//Register Select
#define	LCD_RS_PORT					GPIOB
#define LCD_RS_PIN					GPIO_PIN_9
#define LCD_RS_H					0x00000200
#define LCD_RS_L					0x02000000
//ReaD
#define	LCD_RD_PORT					GPIOB
#define LCD_RD_PIN					GPIO_PIN_10
#define LCD_RD_H					0x00000400
#define LCD_RD_L					0x04000000
//WRite
#define	LCD_WR_PORT					GPIOB
#define LCD_WR_PIN					GPIO_PIN_12
#define LCD_WR_H					0x00001000
#define LCD_WR_L					0x10000000
//ReSeT
#define	LCD_RST_PORT				GPIOC
#define LCD_RST_PIN					GPIO_PIN_10
#define LCD_RST_H					0x00000400
#define LCD_RST_L					0x04000000
//
void LcdWriteReg(U8 Data);
U8 LcdReadData(void);
void LcdWriteData(U8 Data);
void LcdWriteDataMultiple(U8 * pData, int NumItems);
void LcdReadDataMultiple(U8 * pData, int NumItems);
void GPIO_Init(void);
void LcdInit(void);
//void LcdClear(char mode,char color_r,char color_g, char color_b);
void LcdClear(U16 color);
void ReadReg(U8 Reg, U8 * pData, U8 NumItems);
void DrawPixel(U16 x,U16 y,U16 color);
#endif

/* LCDCONF_H */

/*************************** End of file ****************************/
