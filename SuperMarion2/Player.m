//
//  Player.m
//  SuperKoalio
//
//  Created by Jacob Gundersen on 6/4/12.
//  Copyright 2012 Interrobang Software LLC. All rights reserved.
//

#import "Player.h"
#import "SimpleAudioEngine.h"

@implementation Player

@synthesize velocity = _velocity;
@synthesize desiredPosition = _desiredPosition;
@synthesize onGround = _onGround;
@synthesize forwardMarch = _forwardMarch, mightAsWellJump = _mightAsWellJump;

// 1
-(id)initWithFile:(NSString *)filename 
{
    if (self = [super initWithFile:filename]) {
        self.velocity = ccp(0.0, 0.0);
    }
    return self;
}

-(void)update:(ccTime)dt 
{
    
    CGPoint gravity = ccp(0.0, -450.0);
    CGPoint gravityStep = ccpMult(gravity, dt);
    
    CGPoint forwardMove = ccp(800.0, 0.0);
    CGPoint forwardStep = ccpMult(forwardMove, dt);
    
    self.velocity = ccpAdd(self.velocity, gravityStep);
    self.velocity = ccp(self.velocity.x * 0.90, self.velocity.y);
    
    CGPoint jumpForce = ccp(0.0, 310.0);
    float jumpCutoff = 150.0;
    
    if(self.mightAsWellJump && self.onGround) {
        self.velocity = ccpAdd(self.velocity, jumpForce);
        [[SimpleAudioEngine sharedEngine] playEffect:@"jump.wav"];
    }else if(!self.mightAsWellJump && self.velocity.y > jumpCutoff) {
        self.velocity = ccp(self.velocity.x, jumpCutoff);
    }
    
    if(self.forwardMarch) {
        self.velocity = ccpAdd(self.velocity, forwardStep);
    }
    
    CGPoint minMovement = ccp(0.0, -450.0);
    CGPoint maxMovement = ccp(120.0, 250.0);
    self.velocity = ccpClamp(self.velocity, minMovement, maxMovement);
    
    CGPoint stepVelocity = ccpMult(self.velocity, dt);
    // 5
    self.desiredPosition = ccpAdd(self.position, stepVelocity);
}

-(CGRect)collisionBoundingBox {
    CGRect collisionBox = CGRectInset(self.boundingBox, 3, 0);
    CGPoint diff = ccpSub(self.desiredPosition, self.position);
    CGRect returnBoundingBox = CGRectOffset(collisionBox, diff.x, diff.y);
    return returnBoundingBox;
}

@end
