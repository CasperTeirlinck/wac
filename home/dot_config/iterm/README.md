### iTerm2 config
iTerms2 needs some manual steps to use our config.
To bootstrap, iTerm needs to be pointed at our plist. This can be done with the following commands:

```sh
defaults write com.googlecode.iterm2.plist PrefsCustomFolder -string "~/.config/iterm"
defaults write com.googlecode.iterm2.plist LoadPrefsFromCustomFolder -bool true
```

The color theme was impoimported via the UI and is contained within the plist.
When making changes, you can go to Settings -> General -> Settings -> Save Now.