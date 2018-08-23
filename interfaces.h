#import <QuartzCore/QuartzCore.h>
#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <objc/runtime.h>
#import <substrate.h>
#import "BlurBlur.h"
#import "EXSTOCircleMenuView.h"

#define NSLog(...)

#define log(z) NSLog(@"[Exsto] %@", z)
#define prefsID CFSTR("com.zachatrocity.exsto")

#define TWEAK_NAME @"exsto"
#define TWEAK_BUNDLE_PATH [NSString stringWithFormat:@"/Library/PreferenceBundles/%@.bundle", TWEAK_NAME]

// #define TWEAK_PREFS_COLOR [UIColor colorWithRed:0.08f green:0.75f blue:0.85f alpha:1.f]

@interface UIApplication (Private)
-(BOOL)launchApplicationWithIdentifier:(NSString*)bundleID suspended:(BOOL)suspended;
@end

@interface SBIconViewMap : NSObject
-(id)mappedIconViewForIcon:(id)arg1 ;
@end

@interface SBIconModel : NSObject
-(id)expectedIconForDisplayIdentifier:(id)arg1 ;
@end

@interface SBIconController : NSObject
@property (nonatomic,retain) SBIconModel * model; 
@property (nonatomic,readonly) SBIconViewMap * homescreenIconViewMap; 
-(id)contentView;
+(id)sharedInstance;
-(void)_launchFromIconView:(id)arg1 ;
-(id)iconViewForIcon:(id)arg1 location:(long long)arg2 ;
-(void)iconTapped:(id)arg1 ;
-(void)setIsEditing:(BOOL)arg1;
-(void)openFolder:(id)folder animated:(BOOL)animated;
-(NSArray *)anglesBetweenPointA:(CGPoint)a pointB:(CGPoint)b pointC:(CGPoint)c;
-(BOOL)point:(CGPoint)c isOnLineFromPointA:(CGPoint)a toPointB:(CGPoint)b;
-(CGFloat)distanceFromPoint:(CGPoint)a toPointB:(CGPoint)b;
-(NSArray *)pointsAtIntersectWithLineFromOrigin:(CGPoint)origin toTarget:(CGPoint)target withCenter:(CGPoint)center withRadius:(double)radius;
-(CGFloat)checkAndCalculateAngleBetweenPoints:(NSArray *)points center:(CGPoint)center;
-(void)updateEXSTOContextPosition:(CGPoint)center withIconCount:(int)count;
-(NSDictionary *)optionsDictionary;
-(void)removeExstoView;
-(void)iconHandleLongPress:(id)press;
-(EXSTOCircleMenuView *)circleMenuView;
-(void)setCircleMenuView:(EXSTOCircleMenuView *)value;
-(NSMutableArray *)EXSTOImages;
-(void)setEXSTOImages:(NSMutableArray *)value;
-(NSMutableArray *)EXSTOFolderApplications;
-(void)setEXSTOFolderApplications:(NSMutableArray *)value;
-(UILongPressGestureRecognizer *)EXSTORecognizer;
-(void)setEXSTORecognizer:(UILongPressGestureRecognizer *)value;
//-(DFContinuousForceTouchGestureRecognizer *)EXSTOForceRecognizer;
//-(void)setEXSTOForceRecognizer:(DFContinuousForceTouchGestureRecognizer *)value;
@end



@interface SBIconImageView : UIView
-(id)contentsImage;
@end

@interface SBAlertItemsController : NSObject
- (void)activateAlertItem:(id)item;
@end

@interface SBLockScreenManager : NSObject
-(void)lockUIFromSource:(int)arg1 withOptions:(id)arg2;
@end

@interface SBIcon : NSObject
- (void)launchFromLocation:(int)arg1; // iOS 7 & 8
- (void)launchFromLocation:(int)arg1 context:(id)arg2; // iOS 8.3
- (id)applicationBundleID;
- (id)displayName;
- (NSInteger)badgeValue;
- (id)application;
- (id)getIconImage:(int)arg1;
- (id)generateIconImage:(int)arg1;
@end

@interface SBApplication : NSObject
-(id)displayName;
@end

@interface SBIconView : UIView
@property (nonatomic, retain) id delegate;
- (id)initWithDefaultSize;
- (void)_setIcon:(SBIcon*)icon animated:(BOOL)animated;
@end

@interface SBIconListModel : NSObject
-(id)iconAtIndex:(unsigned)index;
-(id)icons;
-(unsigned)numberOfIcons;
@end

@interface SBFolder : NSObject
-(id)allIcons; // returns an NSMutableSet
-(id)visibleIcons; // returns an NSMutableSet
-(id)lists;
@property(copy, nonatomic) NSString *displayName;
@end

@interface SBFolderIconView : UIView
@property (assign,nonatomic) BOOL isEditing;
@property (retain) UILongPressGestureRecognizer* gesturesExsto;
-(id)folder;
-(id)initWithFrame:(CGRect)frame;
-(id)type;
-(BOOL)isInDock;
-(UIView *)contentContainerView;
@end

@interface SBApplicationShortcutMenu : NSObject
- (void)iconHandleLongPress:(id)arg1;
- (void)menuContentView:(id)arg1 activateShortcutItem:(id)arg2 index:(long long)arg3;
@end

@interface SBApplicationShortcutItem : NSObject
@end

@interface SBApplicationShortcutMenuContentView : NSObject
- (id)initWithInitialFrame:(struct CGRect)arg1 containerBounds:(struct CGRect)arg2 orientation:(long long)arg3 shortcutItems:(NSArray <UIApplicationShortcutItem *>*)arg4 application:(SBApplication*)arg5;
@end