#ifndef INC_DHT11_H_
#define INC_DHT11_H_

#include "main.h"
#include "tim.h"



#define DHT11_PORT 		GPIOB
#define DHT11_PIN 		GPIO_PIN_0


extern int Temperature ;
extern int Humidity ;
extern uint8_t temp_buffer[256];


void dht11_delay_us(uint16_t time);
int wait_pulse(int state);
int dht11_read(void);



#endif /* INC_DHT11_H_ */
