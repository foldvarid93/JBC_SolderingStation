/* USER CODE BEGIN Header */
/**
  ******************************************************************************
  * @file           : main.h
  * @brief          : Header for main.c file.
  *                   This file contains the common defines of the application.
  ******************************************************************************
  * @attention
  *
  * <h2><center>&copy; Copyright (c) 2019 STMicroelectronics.
  * All rights reserved.</center></h2>
  *
  * This software component is licensed by ST under BSD 3-Clause license,
  * the "License"; You may not use this file except in compliance with the
  * License. You may obtain a copy of the License at:
  *                        opensource.org/licenses/BSD-3-Clause
  *
  ******************************************************************************
  */
/* USER CODE END Header */

/* Define to prevent recursive inclusion -------------------------------------*/
#ifndef __MAIN_H
#define __MAIN_H

#ifdef __cplusplus
extern "C" {
#endif

/* Includes ------------------------------------------------------------------*/
#include "stm32f4xx_hal.h"

/* Private includes ----------------------------------------------------------*/
/* USER CODE BEGIN Includes */

/* USER CODE END Includes */

/* Exported types ------------------------------------------------------------*/
/* USER CODE BEGIN ET */

/* USER CODE END ET */

/* Exported constants --------------------------------------------------------*/
/* USER CODE BEGIN EC */

/* USER CODE END EC */

/* Exported macro ------------------------------------------------------------*/
/* USER CODE BEGIN EM */

/* USER CODE END EM */

/* Exported functions prototypes ---------------------------------------------*/
void Error_Handler(void);

/* USER CODE BEGIN EFP */

/* USER CODE END EFP */

/* Private defines -----------------------------------------------------------*/
#define ENC_A_Pin GPIO_PIN_0
#define ENC_A_GPIO_Port GPIOA
#define ENC_B_Pin GPIO_PIN_1
#define ENC_B_GPIO_Port GPIOA
#define HEATING_Pin GPIO_PIN_4
#define HEATING_GPIO_Port GPIOA
#define INH_ADC_Pin GPIO_PIN_5
#define INH_ADC_GPIO_Port GPIOA
#define INT_ZC_Pin GPIO_PIN_7
#define INT_ZC_GPIO_Port GPIOA
#define INT_ZC_EXTI_IRQn EXTI9_5_IRQn
#define LCD_D0_Pin GPIO_PIN_0
#define LCD_D0_GPIO_Port GPIOB
#define LCD_D1_Pin GPIO_PIN_1
#define LCD_D1_GPIO_Port GPIOB
#define LCD_D2_Pin GPIO_PIN_2
#define LCD_D2_GPIO_Port GPIOB
#define LCD_RD_Pin GPIO_PIN_10
#define LCD_RD_GPIO_Port GPIOB
#define LCD_WR_Pin GPIO_PIN_12
#define LCD_WR_GPIO_Port GPIOB
#define SDA_Pin GPIO_PIN_9
#define SDA_GPIO_Port GPIOC
#define SCL_Pin GPIO_PIN_8
#define SCL_GPIO_Port GPIOA
#define SNC_Pin GPIO_PIN_12
#define SNC_GPIO_Port GPIOA
#define SNC_EXTI_IRQn EXTI15_10_IRQn
#define SWDIO_Pin GPIO_PIN_13
#define SWDIO_GPIO_Port GPIOA
#define SWDCLK_Pin GPIO_PIN_14
#define SWDCLK_GPIO_Port GPIOA
#define SLEEP_Pin GPIO_PIN_15
#define SLEEP_GPIO_Port GPIOA
#define SLEEP_EXTI_IRQn EXTI15_10_IRQn
#define LCD_RST_Pin GPIO_PIN_10
#define LCD_RST_GPIO_Port GPIOC
#define ENC_BUT_Pin GPIO_PIN_11
#define ENC_BUT_GPIO_Port GPIOC
#define ENC_BUT_EXTI_IRQn EXTI15_10_IRQn
#define LCD_D3_Pin GPIO_PIN_3
#define LCD_D3_GPIO_Port GPIOB
#define LCD_D4_Pin GPIO_PIN_4
#define LCD_D4_GPIO_Port GPIOB
#define LCD_D5_Pin GPIO_PIN_5
#define LCD_D5_GPIO_Port GPIOB
#define LCD_D6_Pin GPIO_PIN_6
#define LCD_D6_GPIO_Port GPIOB
#define LCD_D7_Pin GPIO_PIN_7
#define LCD_D7_GPIO_Port GPIOB
#define LCD_CS_Pin GPIO_PIN_8
#define LCD_CS_GPIO_Port GPIOB
#define LCD_RS_Pin GPIO_PIN_9
#define LCD_RS_GPIO_Port GPIOB

/* USER CODE BEGIN Private defines */
#define LCD_DATA_PORT GPIOB
#define LCDTFT
#define PID_CTRL
//#define	DEBUG
/* USER CODE END Private defines */

#ifdef __cplusplus
}
#endif

#endif /* __MAIN_H */
