# 2019 Hackaday Supercon splash screens

A compilation of multiple splash screens, each inspired by a piece of gaming hardware as befitting the Game Boy form factor of the badge.

Designed to be launched upon startup, the main() function will randomly choose one of the available splash screens to display.

Each splash screen function is fully self-contained and can be copied as starting point to another badge app. They also serve as demonstration for various visual effects possible with the badge's tile-based graphics subsystem.

* _Original Game Boy_: The simplest splash screen, good basis for starter badge projects.
* _Game Boy Color_: Showcases the use of transparency and tile animations.
* _SEGA_: In addition to techniques used by Game Boy Color, also uses palette animation for text fading effect.
* _Nintendo Switch_: Animates both tile maps to achieve its motion effect.
* _PlayStation_: Wave tileset exceeds width of screen to animate off-screen, plus a palette animation affecting opacity of a block of tiles to fake fading antialiased text in and out.
* _Xbox One_: Showcases the ability to scale a tilemap.
