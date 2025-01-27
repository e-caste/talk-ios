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

#import <UIKit/UIKit.h>

@class LoginViewController;
@protocol LoginViewControllerDelegate <NSObject>

- (void)loginViewControllerDidFinish:(LoginViewController *)viewController;

@end

@interface LoginViewController : UIViewController

@property (nonatomic, weak) id<LoginViewControllerDelegate> delegate;

@property (nonatomic, weak) IBOutlet UIImageView *appLogo;
@property (nonatomic, weak) IBOutlet UITextField *serverUrl;
@property (nonatomic, weak) IBOutlet UIImageView *imageBaseUrl;
@property (nonatomic, weak) IBOutlet UIButton *login;
@property (nonatomic, weak) IBOutlet UIButton *cancel;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic, weak) IBOutlet UIButton *qrCodeLogin;

- (void)startLoginProcessWithServerURL:(NSString *)serverURL withUser:(NSString *)user;

@end
