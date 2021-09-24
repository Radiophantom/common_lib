Common library  
---
  
This library contains some common modules that can be  
used in variety of projects  
  
Common library includes:  
* cdc_handshake.sv -  Module to organize simple handshake operation with required CDC stages to prevent metastability.  
    Each request blocks internal logic until handshake acknowledge received. Each acknowledge blocks internal logic  
    until new handshake request received. Such behavior exclude accidentally request or acknowledge signals be  
    processed.  
    Each accepted request responses with acknowledge, even if request signal was deasserted while CDC operation.  
    This means, that you should pay attention and don't mix accidentally asserted requests with its acknowledge.  
    REQ_AMOUNT always leds to same ACK_AMOUNT.  
    ACK signal valid only 1 tick, after that new request can be processed.  
  
Author  
  
 -- Sergei Krivchenko <s.krivchenko@metrotek.ru>  Thu, 23 Sep 2021 14:35:18 +0300  
