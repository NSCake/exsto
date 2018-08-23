#import "interfaces.h"

//static BOOL EXSTO_ENABLED = YES;
//static BOOL EXSTO_GESTURES_DISABLED = NO;
static BOOL EXSTO_LIMIT_ICONS = NO;
static int EXSTO_MAX_ICONS = 0;
static double EXSTO_DELAY_SPEED = 0.2;
static double EXSTO_RADIUS = 80;
static BOOL EXSTO_SHOW_NOTIF_GLOW = YES;
static CGFloat EXSTOangle;
static CGFloat EXSTOdelay;
static int EXSTOshadow;
static CGFloat EXSTOradius;
static CGFloat EXSTOHoverScale;
static CGFloat EXSTObuttonRadius;
static int EXSTOdirection;
static _UIBackdropView *EXSTOWindowBlur;
static NSMutableArray* gesturesAlloc;

%hook SBFolderIconView
%property(retain) id gesturesExsto;
-(id)_folderIconImageView
{	
	if(!gesturesAlloc) {
		gesturesAlloc = [@[] mutableCopy];
	}
	
	SBIconController * iconController = [%c(SBIconController) sharedInstance];
	
	if(!self.gesturesExsto) {
		self.gesturesExsto = [[UILongPressGestureRecognizer alloc] initWithTarget:iconController action:@selector(handleExstoHold:)];
        self.gesturesExsto.minimumPressDuration = EXSTO_DELAY_SPEED;
		//iconController.EXSTORecognizer.delegate = (id<UILongPressGestureRecognizerDelegate>)self;
		[gesturesAlloc addObject:self.gesturesExsto];
	}
	
	if(self.gesturesExsto) {
		self.gesturesExsto.enabled = ![self isEditing];
		[self removeGestureRecognizer:self.gesturesExsto];
		[self addGestureRecognizer:self.gesturesExsto];
		for (UIGestureRecognizer *recognizer in self.gestureRecognizers) {
			[recognizer requireGestureRecognizerToFail:self.gesturesExsto];
		}
	}
	
	return %orig;
}
- (void)dalloc
{
	if(self.gesturesExsto) {
		[gesturesAlloc removeObject:self.gesturesExsto];
	}
	%orig;
}
%end


%hook SBIconController
/*
-(void)iconHandleLongPress:(id)press{
	if ([press isKindOfClass: %c(SBFolderIconView)])
	{
        if(EXSTO_GESTURES_DISABLED){
            NSLog(@"make the jitter happen");
            %orig; //Let the jitter take control
        } 
        //else
        NSLog(@"Exsto Magic");
		//do nothing, let the Exsto Long press recognizers handle it
	}
	else{
        //its not a folder, so disable exsto for a little while and let jitter mode take over
        log(@"remove the gestures");

        if(exstoGestureArray != nil && exstoFolderArray != nil){
            for (int i = 0; i < [exstoFolderArray count]; ++i)
            {
                //remove recognizer
                [exstoFolderArray[i] removeGestureRecognizer: exstoGestureArray[i]];
                EXSTO_GESTURES_DISABLED = YES;
            }
        }

		%orig;
	}
}
*/
-(void)setIsEditing:(BOOL)arg1
{
	/*SBIconController * iconController = [%c(SBIconController) sharedInstance];
    if(iconController.EXSTORecognizer) {
		iconController.EXSTORecognizer.enabled = !arg1;
	}*/
    %orig;
}

%new
- (void)handleExstoHold:(UIGestureRecognizer *)recognizer
{
	if (recognizer.state == UIGestureRecognizerStateBegan)
    {
    	log(@"TOUCH EXSTO BEGIN");
    	//get icons
    	SBFolderIconView *iconView = (SBFolderIconView *)recognizer.view;
    	SBFolder *selectedFolder = [iconView folder];
		self.EXSTOImages = [@[] mutableCopy];
		self.EXSTOFolderApplications = [@[] mutableCopy];
        NSMutableArray *notifArray = [@[] mutableCopy];
		int iconCount = 0;

        bool iconLimitMet = false;
        for(SBIconListModel *page in [selectedFolder lists]){
            if(!iconLimitMet){
                for(SBIcon *icon in [page icons]){
                    iconCount++;
                    log(icon);
                    //determine if icon has notification
                    if(EXSTO_SHOW_NOTIF_GLOW){
                        if((int)[icon badgeValue] > 0){
                            [notifArray addObject:[NSNumber numberWithBool:YES]];
                        } else {
                            [notifArray addObject:[NSNumber numberWithBool:NO]];
                        }
                    } else {
                        [notifArray addObject:[NSNumber numberWithBool:NO]];
                    }
                    log(@"added the glow");

                    //get image
                    UIImage * iconImage = [icon generateIconImage:1];
                    log(@"got the icon image");
                    //add image to array
                    if(iconImage != nil){
                        [self.EXSTOImages addObject: iconImage];
                    }
                    [self.EXSTOFolderApplications addObject: icon];
                    log(@"Added icon");

                    if(EXSTO_LIMIT_ICONS && iconCount == EXSTO_MAX_ICONS){
                        iconLimitMet = true;
                        break;
                    }
                }
            } else {
                break;
            }
        }

		

    	//UIView * contentView = MSHookIvar <UIView *>(self, "_contentView");
        UIView * contentView = [self contentView];
    	//find touch location
    	CGPoint tPoint = [recognizer locationInView:contentView];
    	log(contentView);

    	//get start location
    	CGPoint startPoint;
        if([iconView isInDock])//folder is in dock
        {
            startPoint.x = tPoint.x;
            startPoint.y = tPoint.y;
        } else {
            startPoint.x = iconView.center.x;
    	    startPoint.y = iconView.center.y + 20;
        }


    	EXSTObuttonRadius = 30.0; 
		EXSTOshadow = 0;
		EXSTOHoverScale = 1.4;

    	EXSTOradius = EXSTO_RADIUS + (iconCount * 10 * 0.1);
    	
    	_UIBackdropViewSettings *settings = [_UIBackdropViewSettings settingsForStyle:1];
 
		// initialization of the blur view
		EXSTOWindowBlur = [[_UIBackdropView alloc] initWithFrame:[UIScreen mainScreen].bounds
		                                              autosizesToFitSuperview:NO settings:settings];
		EXSTOWindowBlur.alpha = 0.0;
		[contentView addSubview:EXSTOWindowBlur];

		log(iconView);

		[UIView animateWithDuration:0.3 delay:0.0 options:nil
	    animations:^{
			EXSTOWindowBlur.alpha = 0.75;
	    }
	    completion:^(BOOL finished) { 

	    }];


        [self updateEXSTOContextPosition:startPoint withIconCount: iconCount];
    	//init exsto menu
        self.circleMenuView = [[EXSTOCircleMenuView alloc] initAtOrigin:startPoint usingOptions:[self optionsDictionary] withNotifArray: notifArray withImageArray:self.EXSTOImages];
        //add menu to content view
	    [contentView addSubview:self.circleMenuView];

        self.circleMenuView.delegate = (id<EXSTOCircleMenuDelegate>)self;
        [self.circleMenuView openMenuWithRecognizer:recognizer];
    }
    else if (recognizer.state == UIGestureRecognizerStateEnded)
    {
    	[self removeExstoView];
    }
}

%new
- (void)removeExstoView
{
    //perform clean up
    log(@"removing blur");
    [UIView animateWithDuration:0.2 delay:0.0 options:nil
    animations:^{
        self.circleMenuView.alpha = 0.0;
    }
    completion:^(BOOL finished) { 
        [UIView animateWithDuration:0.3 delay:0.0 options:nil
        animations:^{
            EXSTOWindowBlur.alpha = 0.0;
        }
        completion:^(BOOL finished) { 
            self.circleMenuView = nil;
            self.EXSTOImages = nil;
            self.EXSTOFolderApplications = nil;
        }];
    }];
}

%new
- (void)circleMenuActivatedButtonWithIndex:(int)anIndex
{
    //UIAlertView* tAlert = [[UIAlertView alloc] initWithTitle:@"Circle Menu Action" message:[NSString stringWithFormat:@"Button pressed at index %i.", anIndex] delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil];
    //[tAlert show];
    log(self.EXSTOFolderApplications[anIndex]);
    log(@"launching app");
	
	NSString* bundleId = [self.EXSTOFolderApplications[anIndex] applicationBundleID];
	[[UIApplication sharedApplication] launchApplicationWithIdentifier:bundleId suspended:NO];
}

%new
- (NSDictionary *)optionsDictionary
{
    NSMutableDictionary* tOptions = [NSMutableDictionary new];
    [tOptions setValue:[NSDecimalNumber numberWithFloat:EXSTOdelay] forKey:CIRCLE_MENU_OPENING_DELAY];
    [tOptions setValue:[NSDecimalNumber numberWithFloat:EXSTOangle] forKey:CIRCLE_MENU_MAX_ANGLE];
    [tOptions setValue:[NSDecimalNumber numberWithFloat:EXSTOHoverScale] forKey:CIRCLE_MENU_HOVER_SCALE];
    [tOptions setValue:[NSDecimalNumber numberWithFloat:EXSTOradius] forKey:CIRCLE_MENU_RADIUS];
    [tOptions setValue:[NSNumber numberWithInt:EXSTOdirection] forKey:CIRCLE_MENU_DIRECTION];
    
    [tOptions setValue:[NSNumber numberWithInt:EXSTOshadow] forKey:CIRCLE_MENU_DEPTH];
    [tOptions setValue:[NSDecimalNumber decimalNumberWithString:@"25.0"] forKey:CIRCLE_MENU_BUTTON_RADIUS];
    [tOptions setValue:[NSDecimalNumber decimalNumberWithString:@"0.0"] forKey:CIRCLE_MENU_BUTTON_BORDER_WIDTH];
    
    //
    // Colors
    //
    [tOptions setValue: [UIColor redColor] forKey:CIRCLE_MENU_NOTIF_COLOR];
    [tOptions setValue: [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.0] forKey:CIRCLE_MENU_BUTTON_BACKGROUND_NORMAL];
    [tOptions setValue: [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.0] forKey:CIRCLE_MENU_BUTTON_BACKGROUND_ACTIVE];
    [tOptions setValue: [UIColor whiteColor] forKey:CIRCLE_MENU_BUTTON_BORDER];
    
    return [tOptions copy];
}


%new
- (void)updateEXSTOContextPosition:(CGPoint)center withIconCount:(int)count
{
    CGFloat radius = EXSTOradius + EXSTObuttonRadius;
    
    EXSTOCircleMenuDirection axisXClosestBorder = EXSTOCircleMenuDirectionLeft;
    CGFloat axisXDistance = center.x;
    
    if ([UIScreen mainScreen].bounds.size.width - center.x < center.x)
    {
        axisXClosestBorder = EXSTOCircleMenuDirectionRight;
        axisXDistance = [UIScreen mainScreen].bounds.size.width - center.x;
    }
    
    EXSTOCircleMenuDirection axisYClosestBorder = EXSTOCircleMenuDirectionUp;
    CGFloat axisYDistance = center.y;
    
    if ([UIScreen mainScreen].bounds.size.height - center.y < center.y)
    {
        axisYClosestBorder = EXSTOCircleMenuDirectionDown;
        axisYDistance = [UIScreen mainScreen].bounds.size.height - center.y;
    }
    
    CGPoint topRight = CGPointMake([UIScreen mainScreen].bounds.size.width, 0.0);
    CGPoint bottomRight = CGPointMake([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
    CGPoint topLeft = CGPointZero;
    CGPoint bottomLeft = CGPointMake(0.0, [UIScreen mainScreen].bounds.size.height);
    
    CGPoint menuCenter = center;
    
    NSArray* pointsLeft = [self pointsAtIntersectWithLineFromOrigin:topLeft toTarget:bottomLeft withCenter:menuCenter withRadius:radius];
    NSArray* pointsRight = [self pointsAtIntersectWithLineFromOrigin:topRight toTarget:bottomRight withCenter:menuCenter withRadius:radius];
    
    NSArray* pointsTop = [self pointsAtIntersectWithLineFromOrigin:topLeft toTarget:topRight withCenter:menuCenter withRadius:radius];
    
    NSArray* pointsBottom = [self pointsAtIntersectWithLineFromOrigin:bottomLeft toTarget:bottomRight withCenter:menuCenter withRadius:radius];
    
    CGFloat leftAngle = [self checkAndCalculateAngleBetweenPoints:pointsLeft center:menuCenter];
    CGFloat rightAngle = [self checkAndCalculateAngleBetweenPoints:pointsRight center:menuCenter];
    CGFloat topAngle = [self checkAndCalculateAngleBetweenPoints:pointsTop center:menuCenter];
    CGFloat bottomAngle = [self checkAndCalculateAngleBetweenPoints:pointsBottom center:menuCenter];
    
    NSLog(@"Left: %f", leftAngle);
    NSLog(@"Right: %f", rightAngle);
    NSLog(@"Top: %f", topAngle);
    NSLog(@"Bottom: %f", bottomAngle);
    
    //
    // Calculate available angle
    //
    
    CGFloat totalAngle = 90.0;
    
    /*
     totalAngle -= ( (90.0 - leftAngle) * 2.0);
     totalAngle -= ( (90.0 - rightAngle) * 2.0);
     totalAngle -= ( (90.0 - topAngle) * 2.0);
     totalAngle -= ( (90.0 - bottomAngle) * 2.0);
     */
    
    //
    // Factorizes angle because of menu buttons extending.
    //
    CGFloat angleModifier = 1.0;
    
    //
    // Set menu to open in correct way
    //
    
    if (leftAngle < 90.0 && topAngle < 90.0) // folder is in top left corner
    {
        EXSTOdirection = EXSTOCircleMenuDirectionDown;
        
        totalAngle += leftAngle + topAngle;
        
        angleModifier = 0.65; //0.85
        totalAngle *= angleModifier;
    }
    else if (leftAngle < 90.0 && bottomAngle < 90.0) //bottom left corner
    {
        EXSTOdirection = EXSTOCircleMenuDirectionRight;
        
        totalAngle += leftAngle + bottomAngle;
        
        angleModifier = 0.65; //0.85
        totalAngle *= angleModifier;
    }
    else if (rightAngle < 90.0 && topAngle < 90.0) // top right corner
    {
        EXSTOdirection = EXSTOCircleMenuDirectionLeft;
        
        totalAngle += rightAngle + topAngle;
        
        angleModifier = 0.65; //0.85
        totalAngle *= angleModifier;
    }
    else if (rightAngle < 90.0 && bottomAngle < 90.0) //bottom right corner
    {
        EXSTOdirection = EXSTOCircleMenuDirectionUp;
        
        totalAngle += rightAngle + bottomAngle;
        
        angleModifier = 0.65; //0.85
        totalAngle *= angleModifier;
    }
    else if (rightAngle < 90.0) //right center
    {
        EXSTOdirection = EXSTOCircleMenuDirectionLeft;
        
        totalAngle = 180.0;
    }
    else if (leftAngle < 90.0) //left center
    {
        EXSTOdirection = EXSTOCircleMenuDirectionRight;
        totalAngle = 180.0;
    }
    else if (topAngle < 90.0) //top center
    {
        EXSTOdirection = EXSTOCircleMenuDirectionDown;
        
        totalAngle = 180.0;
    }
    else if (bottomAngle < 90.0) //bottom center
    {
        EXSTOdirection = EXSTOCircleMenuDirectionUp;
        totalAngle = 180.0;
    }
    else
    {
        totalAngle = 360.0;
        EXSTOdirection = EXSTOCircleMenuDirectionUp;
    }
    
    
    NSLog(@"Total: %f", totalAngle);
    
    EXSTOangle = totalAngle;
    
}

%new
- (CGFloat)checkAndCalculateAngleBetweenPoints:(NSArray *)points center:(CGPoint)center
{
    if (points.count == 2)
    {
        NSArray *angles = [self anglesBetweenPointA:[points[0] CGPointValue] pointB:[points[1] CGPointValue] pointC:center];
        
        return [[angles firstObject] doubleValue];
    }
    
    return 90.0;
}

%new
- (NSArray *)pointsAtIntersectWithLineFromOrigin:(CGPoint)origin toTarget:(CGPoint)target withCenter:(CGPoint)center withRadius:(double)radius
{
    CGFloat euclideanAtoB = sqrt(pow(target.x - origin.x, 2.0) + pow(target.y - origin.y, 2.0));
    
    CGVector d = CGVectorMake( (target.x - origin.x) / euclideanAtoB, (target.y - origin.y) / euclideanAtoB);
    
    CGFloat t = (d.dx * (center.x - origin.x)) + (d.dy * (center.y - origin.y));
    
    CGPoint e = CGPointZero;
    
    e.x = (t * d.dx) + origin.x;
    e.y = (t * d.dy) + origin.y;
    
    CGFloat euclideanCtoE = sqrt(pow(e.x - center.x, 2.0) + pow(e.y - center.y, 2.0));
    
    if (euclideanCtoE < radius)
    {
        CGFloat dt = sqrt (pow(radius, 2.0) - pow(euclideanCtoE, 2.0));
        
        CGPoint f = CGPointZero;
        f.x = ((t - dt) * d.dx) + origin.x;
        f.y = ((t - dt) * d.dy) + origin.y;
        
        CGPoint g = CGPointZero;
        g.x = ((t + dt) * d.dx) + origin.x;
        g.y = ((t + dt) * d.dy) + origin.y;
        
        NSMutableArray *points = [NSMutableArray array];
        
        [points addObject:[NSValue valueWithCGPoint:f]];
        [points addObject:[NSValue valueWithCGPoint:g]];
        
        if (![self point:f isOnLineFromPointA:origin toPointB:target])
        {
            
        }
        
        if (![self point:g isOnLineFromPointA:origin toPointB:target])
        {
            
        }
        
        return [points copy];
    }
    else if (fabs(euclideanCtoE - radius) < DBL_EPSILON)
    {
        return @[];
    }
    
    return nil;
}

%new
- (CGFloat)distanceFromPoint:(CGPoint)a toPointB:(CGPoint)b
{
    return sqrt(pow(a.x - b.x, 2.0) + pow(a.y - b.y, 2.0));
}

%new
- (BOOL)point:(CGPoint)c isOnLineFromPointA:(CGPoint)a toPointB:(CGPoint)b
{
    return [self distanceFromPoint:a toPointB:c] + [self distanceFromPoint:c toPointB:b] == [self distanceFromPoint:a toPointB:b];
}

%new
- (NSArray *)anglesBetweenPointA:(CGPoint)a pointB:(CGPoint)b pointC:(CGPoint)c
{
    CGFloat angleAB = atan2(b.y - a.y, b.x - a.x);
    CGFloat angleAC = atan2(c.y - a.y, c.x - a.x);
    CGFloat angleBC = atan2(b.y - c.y, b.x - c.x);
    
    CGFloat angleA = fabs((angleAB - angleAC) * (180 / M_PI));
    CGFloat angleB = fabs((angleAB - angleBC) * (180 / M_PI));
    
    return @[ @(angleA), @(angleB) ];
}

//ASSOCIATED OBJECTS
%new 
-(NSMutableArray *)EXSTOFolderApplications {
	return objc_getAssociatedObject(self, @selector(EXSTOFolderApplications));
}

%new
- (void)setEXSTOFolderApplications:(NSMutableArray *)value {
    objc_setAssociatedObject(self, @selector(EXSTOFolderApplications), value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

%new 
-(NSMutableArray *)EXSTOImages {
	return objc_getAssociatedObject(self, @selector(EXSTOImages));
}

%new
- (void)setEXSTOImages:(NSMutableArray *)value {
    objc_setAssociatedObject(self, @selector(EXSTOImages), value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

%new 
-(UILongPressGestureRecognizer *)EXSTORecognizer {
	return objc_getAssociatedObject(self, @selector(EXSTORecognizer));
}

%new
- (void)setEXSTORecognizer:(UILongPressGestureRecognizer *)value {
    objc_setAssociatedObject(self, @selector(EXSTORecognizer), value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

%new 
-(EXSTOCircleMenuView *)circleMenuView {
	return objc_getAssociatedObject(self, @selector(circleMenuView));
}

%new
- (void)setCircleMenuView:(EXSTOCircleMenuView *)value {
    objc_setAssociatedObject(self, @selector(circleMenuView), value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

%end

//fix for exsto not closing
%hook UIAlertView
-(void)show{
    [[%c(SBIconController) sharedInstance] removeExstoView];
    %orig;
}
%end

%hook SBAlertItemsController
- (void)activateAlertItem:(id)item
{
    [[%c(SBIconController) sharedInstance] removeExstoView];
    %orig;
}
%end

%hook SBLockScreenManager
-(void)lockUIFromSource:(int)arg1 withOptions:(id)arg2{
    [[%c(SBIconController) sharedInstance] removeExstoView];
    %orig;
}
%end

static void prefsChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
    log(@"reload prefs");
    
    NSDictionary *prefs = nil;
    CFArrayRef keyList = CFPreferencesCopyKeyList(prefsID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
    if(keyList) {
        prefs = (NSDictionary *)CFBridgingRelease(CFPreferencesCopyMultiple(keyList, prefsID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost));
        if(!prefs) prefs = [NSDictionary new];
        CFRelease(keyList);
    }

    //EXSTO_ENABLED = !prefs[@"EXSTO_ENABLED"] ? YES : [prefs[@"EXSTO_ENABLED"] boolValue];
    EXSTO_LIMIT_ICONS = !prefs[@"EXSTO_LIMIT_ICONS"] ? NO : [prefs[@"EXSTO_LIMIT_ICONS"] boolValue];
    EXSTO_MAX_ICONS = !prefs[@"EXSTO_MAX_ICONS"] ? 0 : [prefs[@"EXSTO_MAX_ICONS"] intValue];
    EXSTO_DELAY_SPEED = !prefs[@"EXSTO_DELAY_SPEED"] ? 0.2 : [prefs[@"EXSTO_DELAY_SPEED"] doubleValue];
    EXSTO_RADIUS = !prefs[@"EXSTO_RADIUS"] ? 80 : [prefs[@"EXSTO_RADIUS"] doubleValue];
    EXSTO_SHOW_NOTIF_GLOW = !prefs[@"EXSTO_SHOW_NOTIF_GLOW"] ? YES : [prefs[@"EXSTO_SHOW_NOTIF_GLOW"] boolValue];

    // if(!EXSTO_ENABLED){
    //     log(@"remove the gestures");

    //     if(exstoGestureArray != nil && exstoFolderArray != nil){
    //         for (int i = 0; i < [exstoFolderArray count]; ++i)
    //         {
    //             //remove recognizer
    //             [exstoFolderArray[i] removeGestureRecognizer: exstoGestureArray[i]];
    //             EXSTO_GESTURES_DISABLED = YES;
    //         }
    //     }
    // } else { 
    //     log(@"add the gestures");
    //     if(exstoGestureArray != nil && exstoFolderArray != nil){
    //         for (int i = 0; i < [exstoFolderArray count]; ++i)
    //         {
    //             //add recognizer
    //             [exstoFolderArray[i] addGestureRecognizer: exstoGestureArray[i]];
    //             EXSTO_GESTURES_DISABLED = NO;
    //         }
    //     }
    // }
	
	for(UILongPressGestureRecognizer* gest in gesturesAlloc) {
		gest.minimumPressDuration = EXSTO_DELAY_SPEED;
	}

    log(@"prefs loaded success");
}

%ctor
{
	prefsChanged(NULL, NULL, NULL, NULL, NULL);
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, &prefsChanged, (CFStringRef)@"com.zachatrocity.exsto/prefsChanged", NULL, 0);
}
