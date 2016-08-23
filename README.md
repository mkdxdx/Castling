# Castling
Lighting system for LOVE2D

This is my take on light/shadow system for LOVE2D with aim to create something that will render pixel-perfect shadows and will illuminate any scene while being flexible in terms of perfomance according to user's needs.

Usage:
1. Drop "castling" folder somewhere into root of your love2d project (where your main.lua is)
2. require("castling")
3. Declare engine instance somewhere with 
```
MyInstanceName = Castling:new(256)
```
4. Create separate canvas where scene will be rendered to
```
MySceneCanvas = love.graphics.newCanvas(love.graphics:getWidth(),love.graphics:getHeight())
```
5. Add some lightsources with
```
MyInstanceName:addSource(x,y,r,h)
```
6. Create occlusion function that supposedly renders everything that obstructs light like
```
ShadowFunction = function()
  love.graphics.rectangle("fill",0,0,32,32) -- this will draw rectangle as shadow
end
```
7. In your love.draw() loop draw your scene to previously created canvas, and then pass it and occlusion function to a Castling:obscure like
```
love.graphics.setCanvas(MySceneCanvas)
love.graphics.rectangle("fill",0,0,32,32) -- things can be way more complicated than that
love.graphics.setCanvas() -- switch to a "final" canvas which will contain final image

MyInstanceName:obscure(MySceneCanvas,ShadowFunction)
```
8. Watch your scene enter dark ages.
