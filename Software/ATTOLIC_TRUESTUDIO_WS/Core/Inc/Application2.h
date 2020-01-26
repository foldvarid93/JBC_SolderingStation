/*
 * Application.h
 *
 *  Created on: Nov 1, 2019
 */

#ifndef APPLICATION_H_
#define APPLICATION_H_
//
#include "main.h"
#include "tim.h"
#include "stdlib.h"
#include "string.h"
#include "math.h"
#include "adc.h"
#include "i2c.h"
#include "tim.h"
#include "usart.h"
#include "gpio.h"
#include "stdbool.h"
#include "eeprom.h"
#ifdef LCDTFT
#include "crc.h"
#include "DIALOG.h"
#include "GUI.h"
#endif
//
void LCD_text(const char *q);
void LCD_write(unsigned char c, unsigned char d);
void LCD_init(void);
void user_pwm_setvalue(uint16_t value);
void ftoa(float n, char *res, int afterpoint);
void SendMeasurements(void);
void MainTask(void);
void MainInit(void);
void StateMachine(void);
extern void StateMachine(void);
#endif /* APPLICATION_H_ */
