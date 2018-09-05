
module swith_led(
		switch,
		led
		);					    // 模块名led
		
input	[7:0] 	switch;		    //拨码开关
output	[7:0]	led;			//LED灯输出显示

assign led =	switch;			//把拨码开关的数据在LED灯上面显示

endmodule