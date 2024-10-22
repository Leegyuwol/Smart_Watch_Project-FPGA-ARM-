
#ifndef INC_ULTRASONIC_H_
#define INC_ULTRASONIC_H_

#include "main.h"
#include "tim.h"


#define TRIG_PORT 		GPIOA
#define TRIG_PIN 		GPIO_PIN_4

extern uint16_t IC_VALUE1 ;
extern uint16_t IC_VALUE2 ;
extern uint16_t echoTime ;
extern uint16_t captureFlag ;
extern uint16_t distance ;


void HAL_TIM_IC_CaptureCallback(TIM_HandleTypeDef *htim);
void HCSR04_read();




#endif /* INC_ULTRASONIC_H_ */
