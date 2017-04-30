//
//  UserDefine.h
//  HelloIOS
//
//  Created by 毛星辉 on 2017/4/30.
//  Copyright © 2017年 younger. All rights reserved.
//

#ifndef UserDefine_h
#define UserDefine_h

#define SCREEN_H ([[UIScreen mainScreen] bounds].size.height)
#define SCREEN_W ([[UIScreen mainScreen] bounds].size.width)

#define RGBColor(r,g,b) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:1.0]
#define RGBColorAlpha(r,g,b,a) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:(a)]


#endif /* UserDefine_h */
