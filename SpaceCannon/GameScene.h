//
//  GameScene.h
//  SpaceCannon
//

//  Copyright (c) 2014 BenCodes. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@interface GameScene : SKScene <SKPhysicsContactDelegate>

@property (nonatomic) int ammo;
@property (nonatomic) int score;

@end
