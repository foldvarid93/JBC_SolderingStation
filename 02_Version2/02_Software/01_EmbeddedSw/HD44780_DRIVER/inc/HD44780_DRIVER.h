/*
 * Application.h
 *
 *  Created on: Nov 1, 2019
 */

#ifndef APPLICATION_H_
#define APPLICATION_H_
/*includes*/
#include "main.h"
#include "tim.h"
#include "stdlib.h"
#include "string.h"
#include "stdio.h"
#include "math.h"
#include "adc.h"
#include "i2c.h"
#include "tim.h"
#include "usart.h"
#include "gpio.h"
#include "stdbool.h"
#include "eeprom.h"
/*Defines*/

/*Function declarations*/
void LCD_text(const char *q);
void LCD_write(unsigned char c, unsigned char d);
void LCD_init(void);
#endif /* APPLICATION_H_ */
