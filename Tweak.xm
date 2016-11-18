@interface SPTAlbumTrackData : NSObject
- (char)isRatedExplicit;
@end

@interface SPTrack : NSObject
- (char)isExplicit;
@end

@interface SPTPlayerTrack : NSObject
@property (nonatomic,retain) NSURL *URI;
@end

@interface SPTPlayerImpl : NSObject
- (id)skipToNextTrackWithOptions:(id)options;
@end

@interface SPTPlayerState : NSObject
@property (nonatomic,retain) SPTPlayerTrack *track;
@end
@class SettingsSwitchTableViewCell;
@interface UnplayableTracksSettingsSection : NSObject
@property (nonatomic, retain) SettingsSwitchTableViewCell *playExplicitCell;
@end
@interface SettingsSwitchTableViewCell : UITableViewCell
- (id)initWithTitle:(id)title switchValue:(char)toggle target:(id)target action:(SEL)action reuseIdentifier:(id)identifier;
- (id)switchControl;
@end



NSString *currentlyPlayingURI;

%hook SPTCoreCreateOptions
- (void)setIsTablet:(char)isTablet {
	%orig(true);
}
- (void)setEnableMftRulesForPlayer:(char)enable {
	%orig(false);
}
%end

%hook SPTAlbumTrackData
- (char)isPlayable {
	if ([self isRatedExplicit]) {
		return NO;
	} else return %orig;
}
%end

%hook SPTrack
- (char)isAvailable {
	if ([self isExplicit]) return NO;
	else return %orig;
}
- (id)playableTrack {
	if ([self isExplicit]) return nil;
	else return %orig;
}
%end

%hook SPTGaiaPopupController
- (void)player:(id)arg1 stateDidChange:(id)arg2 {
	SPTPlayerImpl *player = arg1;
	SPTPlayerState *state = arg2;
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"prevent_explicit_songs"]) {
		if (state.track) {
			if (![state.track.URI.absoluteString isEqualToString:currentlyPlayingURI]) {
				NSString *songID;
				songID = [[state.track.URI.absoluteString componentsSeparatedByString:@":"] lastObject];
				if (songID) {
					NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://api.spotify.com/v1/tracks/%@",songID]]];
					NSError *error = nil;
					if (data) {
						NSMutableDictionary *response = [NSJSONSerialization JSONObjectWithData:data options: NSJSONReadingMutableContainers error:&error]; 
						if (response) {
							if ([response objectForKey:@"explicit"]) {
								if ([[response objectForKey:@"explicit"] boolValue] == TRUE) {
									currentlyPlayingURI = state.track.URI.absoluteString;
									[player skipToNextTrackWithOptions:nil];
									%orig;
									return;
								}
							}
						}
					}
				}
			}
			currentlyPlayingURI = state.track.URI.absoluteString;
		}
	}
	%orig;
}
%end
%hook SPTNowPlayingManagerImplementation
- (void)player:(id)arg1 stateDidChange:(id)arg2 {
	SPTPlayerImpl *player = arg1;
	SPTPlayerState *state = arg2;
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"prevent_explicit_songs"]) {
		if (state.track) {
			if (![state.track.URI.absoluteString isEqualToString:currentlyPlayingURI]) {
				NSString *songID;
				songID = [[state.track.URI.absoluteString componentsSeparatedByString:@":"] lastObject];
				if (songID) {
					NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://api.spotify.com/v1/tracks/%@",songID]]];
					NSError *error = nil;
					if (data) {
						NSMutableDictionary *response = [NSJSONSerialization JSONObjectWithData:data options: NSJSONReadingMutableContainers error:&error]; 
						if (response) {
							if ([response objectForKey:@"explicit"]) {
								if ([[response objectForKey:@"explicit"] boolValue] == TRUE) {
									currentlyPlayingURI = state.track.URI.absoluteString;
									[player skipToNextTrackWithOptions:nil];
									%orig;
									return;
								}
							}
						}
					}
				}
			}
			currentlyPlayingURI = state.track.URI.absoluteString;
		}
	}
	%orig;
}
%end

%hook UnplayableTracksSettingsSection
%property (nonatomic, retain) SettingsSwitchTableViewCell *playExplicitCell;

- (id)initWithSettingsViewController:(id)settingsController {
	UnplayableTracksSettingsSection *orig = %orig;
	orig.playExplicitCell = [[NSClassFromString(@"SettingsSwitchTableViewCell") alloc] initWithTitle:@"Prevent Explicit Songs"
																						 switchValue:[[NSUserDefaults standardUserDefaults] boolForKey:@"prevent_explicit_songs"]
																						 target:orig
																						 action:@selector(playExplicitSongsChanged:)
																						 reuseIdentifier:@"SwitchTableViewCell"];
	return orig;
}

-(NSInteger)numberOfRows {
	return 2;
}
-(id)cellForRow:(NSInteger)row {
	if (row == 0) return %orig;
	else return self.playExplicitCell;
}
%new
- (void)playExplicitSongsChanged:(UISwitch *)toggle {
	[[NSUserDefaults standardUserDefaults] setBool:[toggle isOn] forKey:@"prevent_explicit_songs"];
}
%end


