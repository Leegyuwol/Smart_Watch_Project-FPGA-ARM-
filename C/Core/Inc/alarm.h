
#ifndef INC_ALARM_H_
#define INC_ALARM_H_

#include "main.h"
#include "tim.h"
#include "usart.h"

extern uint8_t alarm_active ;

void Alarm_On_Off();
void HAL_RTC_AlarmAEventCallback(RTC_HandleTypeDef *hrtc);


#endif /* INC_ALARM_H_ */
