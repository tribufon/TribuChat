//
//  JSQMessagesCollectionViewCell+Timer.h
//  ChatSecure
//
//  Created by com on 8/10/20.
//  Copyright © 2020 Tribu Monster. All rights reserved.
//

#import "JSQMessagesCollectionViewCell.h"

NS_ASSUME_NONNULL_BEGIN

@protocol JSQMessagesCollectionViewCellTimerDelegate <NSObject>

- (void)deleteMessageAt:(NSIndexPath *)indexPath;
- (NSTimeInterval)timerIntervalAt:(NSIndexPath *)indexPath;
- (NSTimeInterval)setUnlockedAt:(NSIndexPath *)indexPath;

@end


// MARK: -
@interface JSQMessagesCollectionViewCell (Timer)

// for lock
- (void)showLock:(BOOL)isShown;

// for timer
@property (strong, nonatomic) id<JSQMessagesCollectionViewCellTimerDelegate> timerDelegate;

@end

NS_ASSUME_NONNULL_END
