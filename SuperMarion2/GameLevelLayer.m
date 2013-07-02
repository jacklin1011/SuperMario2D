//
//  GameLevelLayer.m
//  SuperKoalio
//
//  Created by Jacob Gundersen on 6/4/12.


#import "GameLevelLayer.h"
#import "Player.h"
#import "SimpleAudioEngine.h"
@interface GameLevelLayer() 
{
    CCTMXTiledMap *map;
    Player *player;
    CCTMXLayer *walls;
    CCTMXLayer *hazards;
    BOOL gameOver;
}

@end


@implementation GameLevelLayer

+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	GameLevelLayer *layer = [GameLevelLayer node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
}

-(id) init
{
	// always call "super" init
	// Apple recommends to re-assign "self" with the "super's" return value
	if( (self=[super init]) ) {
        [[SimpleAudioEngine sharedEngine] playBackgroundMusic:@"level1.mp3"];
        CCLayerColor *blueSky = [[CCLayerColor alloc] initWithColor:ccc4(100, 100, 250, 255)];
        [self addChild:blueSky];
        
        map = [[CCTMXTiledMap alloc] initWithTMXFile:@"level1.tmx"];
        [self addChild:map];
        
        walls = [map layerNamed:@"walls"];
        hazards = [map layerNamed:@"hazards"];
        player = [[Player alloc] initWithFile:@"koalio_stand.png"];
        player.position = ccp(100, 50);
        [map addChild:player z:15];
        
        self.isTouchEnabled = YES;
        [self schedule:@selector(update:)];
	}
	return self;
}

-(void)update:(ccTime)dt 
{
    if(gameOver) {
        return;
    }
    [player update:dt];
    [self checkForWin];
    [self handleHazardCollison:player];
    [self checkForAndResolveCollisions:player];
    [self setViewpointCenter:player.position];
    
}

- (CGPoint)tileCoordForPosition:(CGPoint)position 
{
    float x = floor(position.x / map.tileSize.width);
    float levelHeightInPixels = map.mapSize.height * map.tileSize.height;
    float y = floor((levelHeightInPixels - position.y) / map.tileSize.height);
    return ccp(x, y);
}

-(CGRect)tileRectFromTileCoords:(CGPoint)tileCoords 
{
    float levelHeightInPixels = map.mapSize.height * map.tileSize.height;
    CGPoint origin = ccp(tileCoords.x * map.tileSize.width, levelHeightInPixels - ((tileCoords.y + 1) * map.tileSize.height));
    return CGRectMake(origin.x, origin.y, map.tileSize.width, map.tileSize.height);
}

-(NSArray *)getSurroundingTilesAtPosition:(CGPoint)position forLayer:(CCTMXLayer *)layer {
    
    CGPoint plPos = [self tileCoordForPosition:position]; //1
    
    NSMutableArray *gids = [NSMutableArray array]; //2
    
    for (int i = 0; i < 9; i++) { //3
        int c = i % 3;
        int r = (int)(i / 3);
        CGPoint tilePos = ccp(plPos.x + (c - 1), plPos.y + (r - 1));
        if(tilePos.y > (map.mapSize.height - 1)) {
            [self gameOver:0];
            return nil;
        }
        int tgid = [layer tileGIDAt:tilePos]; //4
        
        CGRect tileRect = [self tileRectFromTileCoords:tilePos]; //5
        
        NSDictionary *tileDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                  [NSNumber numberWithInt:tgid], @"gid",
                                  [NSNumber numberWithFloat:tileRect.origin.x], @"x",
                                  [NSNumber numberWithFloat:tileRect.origin.y], @"y",
                                  [NSValue valueWithCGPoint:tilePos],@"tilePos",
                                  nil];
        [gids addObject:tileDict]; //6
        
    }
    
    [gids removeObjectAtIndex:4];
    [gids insertObject:[gids objectAtIndex:2] atIndex:6];
    [gids removeObjectAtIndex:2];
    [gids exchangeObjectAtIndex:4 withObjectAtIndex:6];
    [gids exchangeObjectAtIndex:0 withObjectAtIndex:4]; //7
    
    return (NSArray *)gids;
}

-(void)checkForAndResolveCollisions:(Player *)p {
    
    NSArray *tiles = [self getSurroundingTilesAtPosition:p.position forLayer:walls ]; //1
    if(gameOver) {
        return;
    }
    p.onGround = NO; //////Here
    
    for (NSDictionary *dic in tiles) {
        CGRect pRect = [p collisionBoundingBox]; //3
        
        int gid = [[dic objectForKey:@"gid"] intValue]; //4
        if (gid) {
            CGRect tileRect = CGRectMake([[dic objectForKey:@"x"] floatValue], [[dic objectForKey:@"y"] floatValue], map.tileSize.width, map.tileSize.height); //5
            if (CGRectIntersectsRect(pRect, tileRect)) {
                CGRect intersection = CGRectIntersection(pRect, tileRect);
                int tileIndx = [tiles indexOfObject:dic];
                
                if (tileIndx == 0) {
                    //tile is directly below player
                    p.desiredPosition = ccp(p.desiredPosition.x, p.desiredPosition.y + intersection.size.height);
                    p.velocity = ccp(p.velocity.x, 0.0); //////Here
                    p.onGround = YES; //////Here
                } else if (tileIndx == 1) {
                    //tile is directly above player
                    p.desiredPosition = ccp(p.desiredPosition.x, p.desiredPosition.y - intersection.size.height);
                    p.velocity = ccp(p.velocity.x, 0.0); //////Here
                } else if (tileIndx == 2) {
                    //tile is left of player
                    p.desiredPosition = ccp(p.desiredPosition.x + intersection.size.width, p.desiredPosition.y);
                } else if (tileIndx == 3) {
                    //tile is right of player
                    p.desiredPosition = ccp(p.desiredPosition.x - intersection.size.width, p.desiredPosition.y);
                } else {
                    if (intersection.size.width > intersection.size.height) {
                        //tile is diagonal, but resolving collision vertially
                        p.velocity = ccp(p.velocity.x, 0.0); //////Here
                        float resolutionHeight;
                        if (tileIndx > 5) {
                            resolutionHeight = intersection.size.height;
                            p.onGround = YES; //////Here
                        } else {
                            resolutionHeight = -intersection.size.height;
                        }
                        p.desiredPosition = ccp(p.desiredPosition.x, p.desiredPosition.y + intersection.size.height );
                        
                    } else {
                        float resolutionWidth;
                        if (tileIndx == 6 || tileIndx == 4) {
                            resolutionWidth = intersection.size.width;
                        } else {
                            resolutionWidth = -intersection.size.width;
                        }
                        p.desiredPosition = ccp(p.desiredPosition.x , p.desiredPosition.y + resolutionWidth);
                    } 
                } 
            }
        } 
    }
    p.position = p.desiredPosition; //8
}

-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    for(UITouch *t in touches) {
        CGPoint touchLocation = [self convertTouchToNodeSpace:t];
        if(touchLocation.x > 240) {
            player.mightAsWellJump = YES;
        }else {
            player.forwardMarch = YES;
        }
    }
}

-(void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    for(UITouch *t in touches) {
        CGPoint touchLocation = [self convertTouchToNodeSpace:t];
        // get previous touch and convert it to node space
        CGPoint previousTouchLocation = [t previousLocationInView:[t view]];
        CGSize screenSize = [[CCDirector sharedDirector] winSize];
        previousTouchLocation = ccp(previousTouchLocation.x, screenSize.height - previousTouchLocation.y);
        if(touchLocation.x > 240 && previousTouchLocation.x <= 240) {
            player.forwardMarch = NO;
            player.mightAsWellJump = YES;
        }else if(previousTouchLocation.x > 240 && previousTouchLocation.x <= 240) {
            player.forwardMarch = YES;
            player.mightAsWellJump = NO;
        }
    }
}

-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    for(UITouch *t in touches) {
        CGPoint touchLocation = [self convertTouchToNodeSpace:t];
        if(touchLocation.x < 240) {
            player.forwardMarch = NO;
        }
        else {
            player.mightAsWellJump = NO;
        }
    }
}

-(void)setViewpointCenter:(CGPoint)position
{
    CGSize winSize = [[CCDirector sharedDirector] winSize];
    
    int x = MAX(position.x, winSize.width / 2);
    int y = MAX(position.y, winSize.height / 2);
    x = MIN(x, (map.mapSize.width * map.tileSize.width)
            - winSize.width / 2);
    y = MIN(y, (map.mapSize.height * map.tileSize.height)
            - winSize.height/2);
    CGPoint actualPosition = ccp(x, y);
    
    CGPoint centerOfView = ccp(winSize.width/2, winSize.height/2);
    CGPoint viewPoint = ccpSub(centerOfView, actualPosition);
    map.position = viewPoint;
}

-(void)handleHazardCollison:(Player *)p {
    NSArray *tiles = [self getSurroundingTilesAtPosition:p.position forLayer:hazards];
    for(NSDictionary * dic in tiles) {
        CGRect tileRect = CGRectMake([[dic objectForKey:@"x"] floatValue], [[dic objectForKey:@"y"] floatValue], map.tileSize.width, map.tileSize.height);
        CGRect pRect = [p collisionBoundingBox];
        if([[dic objectForKey:@"gid"] intValue] && CGRectIntersectsRect(pRect, tileRect)) {
            [self gameOver:0];
        }
    }
}

-(void)gameOver:(BOOL)won {
    gameOver = YES;
    
    NSString *gameText;
    if(won) {
        gameText = @"You won!";
    }
    else {
        gameText = @"You have Died!";
        [[SimpleAudioEngine sharedEngine] playEffect:@"hurt.wav"];
    }
    
    CCLabelTTF *diedLabel = [[CCLabelTTF alloc] initWithString:gameText fontName:@"Marker Felt" fontSize:40];
    diedLabel.position = ccp(240, 200);
    CCMoveBy *slideIn = [[CCMoveBy alloc] initWithDuration:1.0 position:ccp(0.0, 250)];
    CCMenuItemImage *replay = [[CCMenuItemImage alloc] initWithNormalImage:@"replay.png" selectedImage:@"replay.png" disabledImage:@"replay.png" block:^(id sender) {
        [[CCDirector sharedDirector] replaceScene:[GameLevelLayer scene]];
    }];
    
    NSArray *menuItems = [NSArray arrayWithObject:replay];
    CCMenu *menu = [[CCMenu alloc] initWithArray:menuItems];
    menu.position = ccp(240, -100);
    [self addChild:menu];
    [self addChild:diedLabel];
    [menu runAction:slideIn];
}

-(void)checkForWin {
    if(player.position.x > 3130) {
        [self gameOver:1];
    }
}

@end
