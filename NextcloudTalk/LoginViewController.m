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

#import "LoginViewController.h"

#import "NextcloudTalk-Swift.h"

#import "AuthenticationViewController.h"
#import "CCCertificate.h"
#import "NCAPIController.h"
#import "NCAppBranding.h"
#import "NCDatabaseManager.h"

@interface LoginViewController () <UITextFieldDelegate, CCCertificateDelegate, AuthenticationViewControllerDelegate, QRCodeLoginControllerDelegate>
{
    AuthenticationViewController *_authenticationViewController;
    QRCodeLoginController *_qrCodeLoginController;
}

@end

@implementation LoginViewController

@synthesize delegate = _delegate;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.appLogo.image = [UIImage imageNamed:@"loginLogo"];
    self.view.backgroundColor = [NCAppBranding brandColor];
    
    NSString *serverUrlPlaceholderText = NSLocalizedString(@"Server address https://…", nil);
    self.serverUrl.textColor = [NCAppBranding brandTextColor];
    self.serverUrl.tintColor = [NCAppBranding brandTextColor];
    self.serverUrl.attributedPlaceholder = [[NSAttributedString alloc] initWithString:serverUrlPlaceholderText
                                                                           attributes:@{NSForegroundColorAttributeName:[[NCAppBranding brandTextColor] colorWithAlphaComponent:0.5]}];
    
    self.login.backgroundColor = [NCAppBranding brandColor];
    self.login.layer.borderColor = [NCAppBranding brandTextColor].CGColor;
    [self.login setTitleColor:[NCAppBranding brandTextColor] forState:UIControlStateNormal];
    
    self.login.layer.cornerRadius = 26;
    self.login.clipsToBounds = YES;
    self.login.titleLabel.minimumScaleFactor = 0.5f;
    self.login.titleLabel.numberOfLines = 1;
    self.login.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.login.layer.borderWidth = 1.0;
    
    [self.login setTitle:NSLocalizedString(@"Log in", nil) forState:UIControlStateNormal];
    
    self.activityIndicatorView.color = [NCAppBranding brandTextColor];
    self.activityIndicatorView.hidden = YES;
    
    self.imageBaseUrl.image = [self.imageBaseUrl.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [self.imageBaseUrl setTintColor:[NCAppBranding brandTextColor]];
    
    self.cancel.hidden = !(multiAccountEnabled && [[NCDatabaseManager sharedInstance] numberOfAccounts] > 0);
    [self.cancel setTitle:NSLocalizedString(@"Cancel", nil) forState:UIControlStateNormal];
    [self.cancel setTitleColor:[NCAppBranding brandTextColor] forState:UIControlStateNormal];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return [NCAppBranding statusBarStyleForBrandColor];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (IBAction)login:(id)sender
{
    NSString *serverInputText = [self.serverUrl.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if ([serverInputText isEqualToString:@""]) {
        [self->_serverUrl becomeFirstResponder];
        return;
    }
    
    [self startLoginProcessWithServerURL:serverInputText withUser:nil];
}

- (IBAction)cancel:(id)sender
{
    [self dismissViewControllerAnimated:true completion:nil];
}

- (IBAction)qrCodeLogin:(id)sender
{
    _qrCodeLoginController = [[QRCodeLoginController alloc] initWithDelegate:self];
    [_qrCodeLoginController scan];
}

- (void)trustedCerticateAccepted
{
    [self login:self];
}

-(BOOL) textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - Login

- (void)startLoginProcessWithServerURL:(NSString *)serverURL withUser:(NSString *)user
{
    // Check whether baseUrl contain protocol. If not add https:// by default.
    if(![serverURL hasPrefix:@"https"] && ![serverURL hasPrefix:@"http"]) {
        serverURL = [NSString stringWithFormat:@"https://%@",serverURL];
    }
    
    // Remove trailing slash
    if([serverURL hasSuffix:@"/"]) {
        serverURL = [serverURL substringToIndex:[serverURL length] - 1];
    }
        
    // Check if valid URL
    NSURL *validServerURL = [NSURL URLWithString:serverURL];
    if (!validServerURL) {
        [self showAlertWithTitle:NSLocalizedString(@"Invalid server address", nil) andMessage:NSLocalizedString(@"Please check that you entered a valid server address.", nil)];
        return;
    }
    
    [self.serverUrl setText:serverURL];
    
    // Remove stored cookies
    NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (NSHTTPCookie *cookie in [storage cookies])
    {
        [storage deleteCookie:cookie];
    }
    
    [self.activityIndicatorView startAnimating];
    self.activityIndicatorView.hidden = NO;
    [[NCAPIController sharedInstance] getServerCapabilitiesForServer:serverURL withCompletionBlock:^(NSDictionary *serverCapabilities, NSError *error) {
        [self.activityIndicatorView stopAnimating];
        self.activityIndicatorView.hidden = YES;
        if (!error) {
            NSArray *talkFeatures = [[[serverCapabilities objectForKey:@"capabilities"] objectForKey:@"spreed"] objectForKey:@"features"];
            // Check minimum required version
            if ([talkFeatures containsObject:kMinimumRequiredTalkCapability]) {
                [self presentAuthenticationViewWithServerURL:serverURL withUser:user];
            } else if (talkFeatures.count == 0) {
                NSString *title = [NSString stringWithFormat:NSLocalizedString(@"%@ not installed", @"{app name} is not installed"), talkAppName];
                NSString *message = [NSString stringWithFormat:NSLocalizedString(@"It seems that %@ is not installed in your server.", @"It seems that {app name} is not installed in your server."), talkAppName];
                [self showAlertWithTitle:title andMessage:message];
            } else {
                NSString *title = [NSString stringWithFormat:NSLocalizedString(@"%@ version not supported", @"{app name} version not supported"), talkAppName];
                NSString *message = [NSString stringWithFormat:NSLocalizedString(@"Please update your server with the latest %@ version available.", @"Please update your server with the latest {app name} version available."), talkAppName];
                [self showAlertWithTitle:title andMessage:message];
            }
        } else {
            // Self signed certificate
            if ([error code] == NSURLErrorServerCertificateUntrusted) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[CCCertificate sharedManager] presentViewControllerCertificateWithTitle:[error localizedDescription] viewController:self delegate:self];
                });
            } else {
                NSString *errorMessage = [NSString stringWithFormat:@"%@\n%@", [error localizedDescription], NSLocalizedString(@"Please check that you entered the correct Nextcloud server address.", nil)];
                [self showAlertWithTitle:NSLocalizedString(@"Nextcloud server not found", nil) andMessage:errorMessage];
            }
        }
    }];
}

- (void)presentAuthenticationViewWithServerURL:(NSString *)serverURL withUser:(NSString *)user
{
    _authenticationViewController = [[AuthenticationViewController alloc] initWithServerUrl:serverURL];
    _authenticationViewController.delegate = self;
    
    if (user) {
        _authenticationViewController.user = user;
    }
    
    [self presentViewController:_authenticationViewController animated:YES completion:nil];
}

#pragma mark - Alerts

- (void)showAlertWithTitle:(NSString *)title andMessage:(NSString *)message
{
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:title
                                 message:message
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* okButton = [UIAlertAction
                               actionWithTitle:NSLocalizedString(@"OK", nil)
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction * _Nonnull action) {
                                    [self->_serverUrl becomeFirstResponder];
                               }];
    
    [alert addAction:okButton];
    
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - AuthenticationViewControllerDelegate

- (void)authenticationViewControllerDidFinish:(AuthenticationViewController *)viewController
{
    if (viewController == _authenticationViewController) {
        [self.delegate loginViewControllerDidFinish:self];
    }
}

#pragma mark - QRCodeLoginControllerDelegate

- (void)readLoginDetailsWithServerUrl:(NSString *)serverUrl user:(NSString *)user password:(NSString *)password
{
    // TODO: Add checks for server-/talk-version
    if (serverUrl && user && password) {
        [[NCSettingsController sharedInstance] addNewAccountForUser:user withToken:password inServer:serverUrl];
        [self.delegate loginViewControllerDidFinish:self];
    }
}

@end
