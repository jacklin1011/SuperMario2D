//
//  Player.h
//  SuperMarion2
//
//  Created by 林光海 on 13-7-1.
//
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

@interface Player : CCSprite

@property (nonatomic, assign) CGPoint velocity;
@property (nonatomic, assign) CGPoint desiredPosition;
@property (nonatomic, assign) BOOL onGround;
@property (nonatomic, assign) BOOL forwardMarch;
@property (nonatomic, assign) BOOL mightAsWellJump;
-(void)update:(ccTime)dt;
-(CGRect)collisionBoundingBox;
@end
