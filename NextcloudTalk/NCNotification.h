/**
 * @copyright Copyright (c) 2020 Ivan Sein <ivan@nextcloud.com>
 *
 * @author Ivan Sein <ivan@nextcloud.com>
 *
 * @license GNU GPL version 3 or any later version
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

#import <Foundation/Foundation.h>

typedef enum NCNotificationType {
    kNCNotificationTypeRoom = 0,
    kNCNotificationTypeChat,
    kNCNotificationTypeCall
} NCNotificationType;

@interface NCNotification : NSObject

@property (nonatomic, assign) NSInteger notificationId;
@property (nonatomic, strong) NSString *app;
@property (nonatomic, strong) NSString *objectId;
@property (nonatomic, strong) NSString *objectType;
@property (nonatomic, strong) NSString *subject;
@property (nonatomic, strong) NSString *subjectRich;
@property (nonatomic, strong) NSDictionary *subjectRichParameters;
@property (nonatomic, strong) NSString *message;
@property (nonatomic, strong) NSString *messageRich;
@property (nonatomic, strong) NSDictionary *messageRichParameters;

+ (instancetype)notificationWithDictionary:(NSDictionary *)notificationDict;
- (NCNotificationType)notificationType;
- (NSString *)chatMessageAuthor;
- (NSString *)chatMessageTitle;
- (NSString *)callDisplayName;
- (NSString *)roomToken;

@end
