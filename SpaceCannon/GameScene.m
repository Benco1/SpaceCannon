//
//  GameScene.m
//  SpaceCannon
//
//  Created by BC on 12/26/14.
//  Copyright (c) 2014 BenCodes. All rights reserved.
//

#import "GameScene.h"

@implementation GameScene
{
    SKNode *_mainLayer;
    SKSpriteNode *_cannon;
    SKSpriteNode *_ammoDisplay;
    SKLabelNode *_scoreLabel;
    BOOL _didShoot;
}

static const CGFloat SHOOT_SPEED = 600;
static const CGFloat HALO_SPEED = 100;
static const CGFloat HALO_LOW_ANGLE = 200 * M_PI / 180.0;
static const CGFloat HALO_HIGH_ANGLE = 200 * M_PI / 180.0;

static const uint32_t haloCategory = 0x1 << 0;
static const uint32_t ballCategory = 0x1 << 1;
static const uint32_t edgeCategory = 0x1 << 2;
static const uint32_t shieldCategory = 0x1 << 3;
static const uint32_t lifebarCategory = 0x1 << 4;



static inline CGFloat randomInRange(CGFloat low, CGFloat high)
{
    // Get random value between 0 and 1;
    CGFloat value = arc4random_uniform(UINT32_MAX) / (CGFloat)UINT32_MAX;
    
    // Scale, translate and return random value
    return value * (high - low) + low;
    
}

static inline CGVector radiansToVector(CGFloat radians)
{
    CGVector vector;
    vector.dx = cosf(radians);
    vector.dy = sinf(radians);
    return vector;
}

-(void)didMoveToView:(SKView *)view {
    /* Setup your scene here */
    
    self.physicsWorld.gravity = CGVectorMake(0, 0);
    self.physicsWorld.contactDelegate = self;

    SKSpriteNode *background = [SKSpriteNode spriteNodeWithImageNamed:@"Starfield"];
    background.position = CGPointZero;
    background.anchorPoint = CGPointZero;
    [self addChild:background];
    
    // Add edges
    SKNode *leftEdge = [[SKNode alloc] init];
    leftEdge.physicsBody = [SKPhysicsBody bodyWithEdgeFromPoint:CGPointZero toPoint:CGPointMake(0.0, self.size.height)];
    leftEdge.physicsBody.categoryBitMask = edgeCategory;
    leftEdge.position = CGPointZero;
    [self addChild:leftEdge];
    
    SKNode *rightEdge = [[SKNode alloc] init];
    rightEdge.physicsBody = [SKPhysicsBody bodyWithEdgeFromPoint:CGPointZero toPoint:CGPointMake(0.0, self.size.height)];
    rightEdge.physicsBody.categoryBitMask = edgeCategory;
    rightEdge.position = CGPointMake(self.size.width, 0.0);
    [self addChild:rightEdge];
    
    // Setup score display
    _scoreLabel = [SKLabelNode labelNodeWithFontNamed:@"DIN Alternate"];
    _scoreLabel.position = CGPointMake(15, 10);
    _scoreLabel.fontSize = 20.0;
    _scoreLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
    [self addChild:_scoreLabel];
    
    // Add mainLayer
    _mainLayer = [[SKNode alloc] init];
    [self addChild:_mainLayer];
    
    // Add cannon
    _cannon = [SKSpriteNode spriteNodeWithImageNamed:@"spriteCannon"];
    _cannon.name = @"cannon";
    _cannon.position = CGPointMake(self.frame.size.width/2, 0.0);
    [self addChild:_cannon];
    
    // Create cannon rotation
    SKAction *rotateCannon = [SKAction sequence:@[[SKAction rotateByAngle:M_PI duration:2],
                                                  [SKAction rotateByAngle:-M_PI duration:2]]];
    [_cannon runAction:[SKAction repeatActionForever:rotateCannon]];
    
    // Create spawn halo actions
    SKAction *spawnHalo = [SKAction sequence:@[[SKAction waitForDuration:2 withRange:1],
                                               [SKAction performSelector:@selector(spawnHalo) onTarget:self]]];
    
   [self runAction:[SKAction repeatActionForever:spawnHalo]];
    
    // Setup Ammo
    _ammoDisplay = [SKSpriteNode spriteNodeWithImageNamed:@"Ammo5"];
    _ammoDisplay.anchorPoint = CGPointMake(0.5, 0.0);
    _ammoDisplay.position = _cannon.position;
    [self addChild:_ammoDisplay];

    
    SKAction *incrementAmmo = [SKAction sequence:@[[SKAction waitForDuration:1],
                                                   [SKAction runBlock:^{
        self.ammo++;
    }]]];
    [self runAction:[SKAction repeatActionForever:incrementAmmo]];
    
    [self newGame];
    

}

-(void)newGame
{
    self.ammo = 5;
    self.score = 0;
    [_mainLayer removeAllChildren];
    
    // Setup Shields
    [self runAction:[SKAction playSoundFileNamed:@"ShieldUp.caf" waitForCompletion:NO]];
    for (int i = 0; i < 6; i++) {
        SKSpriteNode *shield = [SKSpriteNode spriteNodeWithImageNamed:@"Block"];
        shield.position = CGPointMake(35 + (50 * i), 90);
        shield.name = @"Shield";
        [_mainLayer addChild: shield];
        shield.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:CGSizeMake(42, 9)];
        shield.physicsBody.dynamic = NO;
        shield.physicsBody.categoryBitMask = shieldCategory;
        shield.physicsBody.collisionBitMask = 0;
    }
    
    // Add lifebar
    SKSpriteNode *lifebar = [SKSpriteNode spriteNodeWithImageNamed:@"BlueBar"];
    lifebar.anchorPoint = CGPointMake(0.5, 0.5);
    lifebar.position = CGPointMake(self.size.width/2, 80);
    lifebar.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:CGSizeMake(lifebar.size.width, 10)];
    lifebar.physicsBody.dynamic = NO;
    lifebar.physicsBody.categoryBitMask = lifebarCategory;
    lifebar.physicsBody.collisionBitMask = 0;
    [_mainLayer addChild:lifebar];
}

// Override setter method for ammo property
-(void)setAmmo:(int)ammo
{
    if (ammo >= 0 && ammo <= 5) {
        _ammo = ammo;
        _ammoDisplay.texture = [SKTexture textureWithImageNamed:[NSString stringWithFormat:@"Ammo%d", ammo]];
    }
}

-(void)setScore:(int)score
{
    _score = score;
    _scoreLabel.text = [NSString stringWithFormat:@"Score: %d", score];
}

-(void)spawnHalo
{
    // Create halo
    SKSpriteNode *halo = [SKSpriteNode spriteNodeWithImageNamed:@"Halo"];
    halo.name = @"Halo";
    halo.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:0.7 * halo.size.width/2];
    halo.physicsBody.restitution = 1.0;
    halo.physicsBody.friction = 0.0;
    halo.physicsBody.linearDamping = 0.0;
    halo.physicsBody.categoryBitMask = haloCategory;
    halo.physicsBody.collisionBitMask = edgeCategory;
    halo.physicsBody.contactTestBitMask = ballCategory | shieldCategory | lifebarCategory;
    halo.position = CGPointMake(randomInRange(0, self.size.width), self.size.height);
    
    CGVector haloDirection = radiansToVector(randomInRange(HALO_LOW_ANGLE, HALO_HIGH_ANGLE));
    halo.physicsBody.velocity = CGVectorMake(haloDirection.dx * HALO_SPEED, haloDirection.dy * HALO_SPEED);
    
    [_mainLayer addChild:halo];
}

-(void)shoot
{
    if (self.ammo > 0) {
        self.ammo--;
        SKSpriteNode *ball = [SKSpriteNode spriteNodeWithImageNamed:@"Ball"];
        ball.name = @"Ball";
        CGVector rotationVector = radiansToVector(_cannon.zRotation);
        ball.position = CGPointMake(_cannon.position.x + (_cannon.size.width/2 * rotationVector.dx),
                                    _cannon.position.y + (_cannon.size.height/2 * rotationVector.dy));
        [_mainLayer addChild:ball];
        
        ball.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:0.6 * ball.size.height/2];
        ball.physicsBody.velocity = CGVectorMake(rotationVector.dx * SHOOT_SPEED, rotationVector.dy * SHOOT_SPEED);
        ball.physicsBody.friction = 0.0;
        ball.physicsBody.restitution = 1.0;
        ball.physicsBody.linearDamping = 0.0;
        ball.physicsBody.density = 0.8;
        ball.physicsBody.categoryBitMask = ballCategory;
        ball.physicsBody.collisionBitMask = edgeCategory;
        ball.physicsBody.contactTestBitMask = edgeCategory;
    }
}

-(void)handleCleanup
{
    [_mainLayer enumerateChildNodesWithName:@"Ball" usingBlock:^(SKNode *node, BOOL *stop) {
        
        if (!CGRectContainsPoint(self.frame, node.position)) {
            [node removeFromParent];
        }
    }];
}

-(void)didBeginContact:(SKPhysicsContact *)contact
{
    SKPhysicsBody *firstBody;
    SKPhysicsBody *secondBody;
    
    if (contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask) {
        firstBody = contact.bodyA;
        secondBody = contact.bodyB;
    } else {
        firstBody = contact.bodyB;
        secondBody = contact.bodyA;
    }
    
    if (firstBody.categoryBitMask == haloCategory && secondBody.categoryBitMask == ballCategory) {
        self.score++;
        [self runAction:[SKAction playSoundFileNamed:@"Explosion.caf" waitForCompletion:NO]];
        [self addExplosion:firstBody.node.position withName:@"HaloExplosion"];
        [firstBody.node removeFromParent];
        [secondBody.node removeFromParent];

    }
    if (firstBody.categoryBitMask == haloCategory && secondBody.categoryBitMask == shieldCategory) {
        [self runAction:[SKAction playSoundFileNamed:@"Zap.caf" waitForCompletion:NO]];
        [self addExplosion:firstBody.node.position withName:@"HaloExplosion"];
        [firstBody.node removeFromParent];
        [secondBody.node removeFromParent];
    }
    if (firstBody.categoryBitMask == ballCategory && secondBody.categoryBitMask == edgeCategory) {
        [self runAction:[SKAction playSoundFileNamed:@"Bounce.caf" waitForCompletion:NO]];
        [self addExplosion:firstBody.node.position withName:@"BallBurst"];
    }
    if (firstBody.categoryBitMask == haloCategory && secondBody.categoryBitMask == lifebarCategory) {
        [self runAction:[SKAction playSoundFileNamed:@"DeepExplosion.caf" waitForCompletion:NO]];
        [self addExplosion:secondBody.node.position withName:@"HaloExplosion"];
        [secondBody.node removeFromParent];
        [self gameOver];
    }
}

-(void)gameOver
{
    [_mainLayer enumerateChildNodesWithName:@"Halo" usingBlock:^(SKNode *node, BOOL *stop) {
        [self addExplosion:node.position withName:@"HaloExplosion"];
        [node removeFromParent];
    }];
    [_mainLayer enumerateChildNodesWithName:@"Ball" usingBlock:^(SKNode *node, BOOL *stop) {
        [self addExplosion:node.position withName:@"HaloExplosion"];
        [node removeFromParent];
    }];
    [_mainLayer enumerateChildNodesWithName:@"Shield" usingBlock:^(SKNode *node, BOOL *stop) {
        [self addExplosion:node.position withName:@"HaloExplosion"];
        [node removeFromParent];
    }];
    [self performSelector:@selector(newGame) withObject:nil afterDelay:1.5];
}

-(void)addExplosion:(CGPoint)position withName:(NSString *)name
{
    NSString *explosionPath = [[NSBundle mainBundle] pathForResource:name ofType:@"sks"];
    SKEmitterNode *explosion = [NSKeyedUnarchiver unarchiveObjectWithFile:explosionPath];
    
    explosion.position = position;
    [_mainLayer addChild:explosion];
    
    SKAction *removeExplosion = [SKAction sequence:@[[SKAction waitForDuration:1.5],
                                                     [SKAction removeFromParent]]];
    [explosion runAction:removeExplosion];
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    /* Called when a touch begins */
        _didShoot = YES;
}

-(void)didSimulatePhysics
{
    if (_didShoot == YES) {
        [self runAction:[SKAction playSoundFileNamed:@"Laser.caf" waitForCompletion:NO]];
        [self shoot];
        _didShoot = NO;
    }

    [self handleCleanup];
}

-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */

}

@end
