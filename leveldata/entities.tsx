<?xml version="1.0" encoding="UTF-8"?>
<tileset version="1.8" tiledversion="1.8.2" name="entities" tilewidth="96" tileheight="96" tilecount="9" columns="0" objectalignment="topleft">
 <grid orientation="orthogonal" width="1" height="1"/>
 <tile id="0">
  <image width="32" height="32" source="../assets/ghost.png"/>
 </tile>
 <tile id="1">
  <image width="96" height="96" source="../assets/level_start.png"/>
 </tile>
 <tile id="2">
  <image width="96" height="96" source="../assets/level_end.png"/>
 </tile>
 <tile id="3">
  <image width="64" height="64" source="../assets/ghost-arm.png"/>
 </tile>
 <tile id="5">
  <image width="64" height="80" source="../assets/spider3.png"/>
 </tile>
 <tile id="6">
  <image width="64" height="80" source="../assets/spider2.png"/>
 </tile>
 <tile id="7">
  <image width="64" height="80" source="../assets/spider1.png"/>
  <animation>
   <frame tileid="7" duration="100"/>
   <frame tileid="6" duration="100"/>
   <frame tileid="5" duration="100"/>
  </animation>
 </tile>
 <tile id="8">
  <image width="32" height="34" source="../assets/candle-ghost-tiled.png"/>
 </tile>
 <tile id="9">
  <image width="64" height="12" source="../assets/moving-platform.png"/>
 </tile>
</tileset>
