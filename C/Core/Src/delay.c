
#include "delay.h"




void delay_us(uint16_t us)
{
    // 타이머 카운터를 0으로 초기화
    __HAL_TIM_SET_COUNTER(&htim11, 0);

    // 타이머 카운터가 지정된 마이크로초(us) 값에 도달할 때까지 대기
    while ((__HAL_TIM_GET_COUNTER(&htim11)) < us);
}
