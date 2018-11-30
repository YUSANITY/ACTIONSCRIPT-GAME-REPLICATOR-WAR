package {
	import flash.display.*;
	import flash.events.*;
	import flash.text.*;
	import flash.utils.getTimer;
	import flash.utils.Timer;
	import flash.geom.Point;
	import flash.ui.Mouse;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.display.Stage;


	public class SpaceRocks extends MovieClip {
		static const shipRotationSpeed:Number = .1;
		static const rockSpeedStart:Number = .03;
		static const rockSpeedIncrease:Number = .02;
		static const missileSpeed:Number = .2;
		static const thrustPower:Number = .15;
		static const shipRadius:Number = 20;
		static const startingShips:uint = 3;
	
		// game objects
		private var ship:Ship;
		private var rocks:Array;
		private var missiles:Array;
		
		// animation timer
		private var lastTime:uint;
		
		// arrow keys
		private var rightArrow:Boolean = false;
		private var leftArrow:Boolean = false;
		private var upArrow:Boolean = false;
		
		// ship velocity
		private var shipMoveX:Number;
		private var shipMoveY:Number;
		
		// timers
		private var delayTimer:Timer;
		private var shieldTimer:Timer;
		
		// game mode
		private var gameMode:String;
		private var shieldOn:Boolean;
		
		// ships and shields
		private var shipsLeft:uint;
		private var shieldsLeft:uint;
		private var shipIcons:Array;
		private var shieldIcons:Array;
		private var scoreDisplay:TextField;

		// score and level
		private var gameScore:Number;
		private var gameLevel:uint;

		// sprites
		private var gameObjects:Sprite;
		private var scoreObjects:Sprite;
		
		private var _container:MovieClip;
		
		// Setup the laser sound.
		var theLaserSound:laser = new laser();
		var theExplosionSound:explosion = new explosion();
		
		// start the game
		public function startSpaceRocks(container:MovieClip, stageRef:Stage) {
			// set up sprites
			_container = container;
			
			gameObjects = new Sprite();
			_container.addChild(gameObjects);
			scoreObjects = new Sprite();
			_container.addChild(scoreObjects);
			
			// reset score objects
			gameLevel = 1;
			shipsLeft = startingShips;
			gameScore = 0;
			createShipIcons();
			createScoreDisplay();

			// set up listeners
			_container.addEventListener(Event.ENTER_FRAME,moveGameObjects, false, 0, true);
			
			stageRef.addEventListener(KeyboardEvent.KEY_DOWN,keyDownFunction);
			stageRef.addEventListener(KeyboardEvent.KEY_UP,keyUpFunction);
			
			//_container.addEventListener(MouseEvent.MOUSE_MOVE,followMouse, false, 0, true);
			_container.addEventListener(MouseEvent.MOUSE_MOVE,followMouse);
			
			_container.addEventListener(MouseEvent.MOUSE_DOWN,mouseLeftButtonDown, false, 0, true);

			//Mouse.hide();
			
			// start 
			gameMode = "delay";
			shieldOn = false;
			missiles = new Array();
			nextRockWave(null);
			newShip(null);
			_container.focusRect = ship;

		}

		// SCORE OBJECTS
		
		// draw number of ships left
		public function createShipIcons() {
			shipIcons = new Array();
			for(var i:uint=0;i<shipsLeft;i++) {
				var newShip:ShipIcon = new ShipIcon();
				newShip.x = 20+i*30;
			
			// Use the screen height to calculate the score position.
				newShip.y = _container.height - 50;
				scoreObjects.addChild(newShip);
				shipIcons.push(newShip);
			}
		}
		
		// draw number of shields left
		public function createShieldIcons() {
			shieldIcons = new Array();
			for(var i:uint=0;i<shieldsLeft;i++) {
				var newShield:ShieldIcon = new ShieldIcon();
				newShield.x = 750 -i*30;
				newShield.y = _container.height - 50;
				scoreObjects.addChild(newShield);
				shieldIcons.push(newShield);
			}
		}
		
		// put the numerical score at the upper right
		public function createScoreDisplay() {
			scoreDisplay = new TextField();
			
			scoreDisplay.x = _container.width - 150;
			scoreDisplay.y = 10;
			scoreDisplay.width = 100;
			scoreDisplay.selectable = false;
			var scoreDisplayFormat = new TextFormat();
			scoreDisplayFormat.color = 0xFFFFFF;
			scoreDisplayFormat.font = "Arial";
			scoreDisplayFormat.align = "right";
			scoreDisplayFormat.size = "40";
			scoreDisplayFormat.bold = true;
			scoreDisplay.defaultTextFormat = scoreDisplayFormat;
			scoreObjects.addChild(scoreDisplay);
			updateScore();
		}
		
		// new score to show
		public function updateScore() {
			scoreDisplay.text = String(gameScore);
		}
		
		// remove a ship icon
		public function removeShipIcon() {
			scoreObjects.removeChild(shipIcons.pop());
		}
		
		// remove a shield icon
		public function removeShieldIcon() {
			scoreObjects.removeChild(shieldIcons.pop());
		}
		
		// remove the rest of the ship icons
		public function removeAllShipIcons() {
			while (shipIcons.length > 0) {
				removeShipIcon();
			}
		}
		
		// remove the rest of the shield icons
		public function removeAllShieldIcons() {
			while (shieldIcons.length > 0) {
				removeShieldIcon();
			}
		}
		
		// SHIP CREATION AND MOVEMENT
		
		// create a new ship
		public function newShip(event:TimerEvent) {

			// if ship exists, remove it
			if (ship != null) {
				gameObjects.removeChild(ship);
				this.ship = null;
			}
			
			// no more ships
			if (shipsLeft < 1) {
				endGame();
				return;
			}
			
			// create, position, and add new ship
			ship = new Ship();
			
			ship.gotoAndStop(1);

		
		// This section reposition the ship in the central of the scren.

			ship.x = _container.width / 2;

			ship.y = _container.height / 2;
			
			ship.rotation = -90;
			ship.shield.visible = false;
			gameObjects.addChild(ship);
			
			// set up ship properties
			shipMoveX = 0.0;
			shipMoveY = 0.0;
			gameMode = "play_AG";
			
			// set up shields
			shieldsLeft = 3;
			createShieldIcons();
									
			// all lives but the first start with a free shield
			if (shipsLeft != startingShips) {
				startShield(true);
			}
		}
		
	// register key presses
		public function keyDownFunction(event:KeyboardEvent) {

			if (event.keyCode == 37) {
					leftArrow = true;
			} else if (event.keyCode == 39) {
					rightArrow = true;
			} else if (event.keyCode == 38) {
					upArrow = true;
					// show thruster
					if (gameMode == "play_AG") ship.gotoAndStop(2);
			} else if (event.keyCode == 32) { // space
					newMissile();
					playSound(theLaserSound);
			} else if (event.keyCode == 90) { // z
					startShield(false);
			}
		}
			
		// register key ups
		public function keyUpFunction(event:KeyboardEvent) {
			if (event.keyCode == 37) {
				leftArrow = false;
			} else if (event.keyCode == 39) {
				rightArrow = false;
			} else if (event.keyCode == 38) {
				upArrow = false;
				// remove thruster
				if (gameMode == "play_AG") ship.gotoAndStop(1);
			}
		}
		
		// Setup the event listener for the ship to move follow the mouse. 
		function followMouse(event:MouseEvent):void {
			var dx:int =  ship.x - mouseX;
			var dy:int =  ship.y - mouseY;
					
			ship.x -= dx;
			ship.y -= dy;

		}
		
		function mouseLeftButtonDown(event:MouseEvent):void {
			_container.addEventListener(Event.ENTER_FRAME, onStageEnterFrame, false, 0, true);
			_container.addEventListener( MouseEvent.MOUSE_UP , mouseLeftButtonUp, false, 0, true);
		}
		
		function mouseLeftButtonUp(e:MouseEvent):void
        {
            _container.removeEventListener(Event.ENTER_FRAME, onStageEnterFrame);
            _container.removeEventListener(MouseEvent.MOUSE_UP, mouseLeftButtonUp);

        }// end function
		
		
		private function onStageEnterFrame(e:Event):void
        {
            newMissile();
			playSound(theLaserSound);
        }// end function
		
		// animate ship
		public function moveShip(timeDiff:uint) {
			// rotate and thrust
			if (leftArrow) {
				ship.rotation -= shipRotationSpeed*timeDiff;
			} else if (rightArrow) {
				ship.rotation += shipRotationSpeed*timeDiff;
			} else if (upArrow) {
				shipMoveX += Math.cos(Math.PI*ship.rotation/180)*thrustPower;
				shipMoveY += Math.sin(Math.PI*ship.rotation/180)*thrustPower;
			}
			
			// move
			ship.x += shipMoveX;
			ship.y += shipMoveY;
			
			// wrap around screen
			if ((shipMoveX > 0) && (ship.x > 780)) {
				ship.x -= 780;
			}
			if ((shipMoveX < 0) && (ship.x < 10)) {
				ship.x += 770;
			}
			if ((shipMoveY > 0) && (ship.y > 580)) {
				ship.y -= 580;
			}
			if ((shipMoveY < 0) && (ship.y < 10)) {
				ship.y += 580;
			}
		}
		
		// remove ship
		public function shipHit() {
			gameMode = "delay";
			ship.gotoAndPlay("explode");
			removeAllShieldIcons();
			delayTimer = new Timer(2000,1);
			delayTimer.addEventListener(TimerEvent.TIMER_COMPLETE,newShip, false, 0, true);
			delayTimer.start();
			removeShipIcon();
			shipsLeft--;
		}
		
		// turn on shield for 10 seconds
		public function startShield(freeShield:Boolean) {
			if (shieldsLeft < 1) return; // no shields left
			if (shieldOn) return; // shield already on
			
			// turn on shield and set timer to turn off
			ship.shield.visible = true;
			shieldTimer = new Timer(10000,1);
			shieldTimer.addEventListener(TimerEvent.TIMER_COMPLETE,endShield, false, 0, true);
			shieldTimer.start();
			
			// update shields remaining
			if (!freeShield) {
				removeShieldIcon();
				shieldsLeft--;
			}
			shieldOn = true;
		}
		
		// turn off shield
		public function endShield(event:TimerEvent) {
			ship.shield.visible = false;
			shieldOn = false;
		}
		
		// ROCKS		
		
		// create a single rock of a specific size
		public function newRock(x,y:int, rockType:String) {
			
			// create appropriate new class
			var newRock:MovieClip;
			var rockRadius:Number;
			if (rockType == "Big") {
				newRock = new Rock_Big();
				rockRadius = 35;
			} else if (rockType == "Medium") {
				newRock = new Rock_Medium();
				rockRadius = 20;
			} else if (rockType == "Small") {
				newRock = new Rock_Small();
				rockRadius = 10;
			}
			
			// choose a random look
			newRock.gotoAndStop(Math.ceil(Math.random()*3));
			
			// set start position
			newRock.x = x;
			newRock.y = y;
			
			// set random movement and rotation
			var dx:Number = Math.random()*2.0-1.0;
			var dy:Number = Math.random()*2.0-1.0;
			var dr:Number = Math.random();
			
			// add to stage and to rocks list
			gameObjects.addChild(newRock);
			rocks.push({rock:newRock, dx:dx, dy:dy, dr:dr, rockType:rockType, rockRadius: rockRadius});
		}
		
		// create four rocks
		public function nextRockWave(event:TimerEvent) {
			rocks = new Array();
			
			// Create rock at upper stretch of screen.
			newRock(50,70,"Big");
			newRock(100,70,"Big");
			newRock(150,70,"Big");
			newRock(200,70,"Big");
			newRock(250,70,"Big");
			newRock(280,70,"Big");
			newRock(300,70,"Big");
			newRock(320,70,"Big");
			newRock(340,70,"Big");
			newRock(360,70,"Big");
			
			gameMode = "play_AG";
			
			// Check the game winning score.
			if (gameScore >= 2080)
			{
				this.endGame();
				_container.gotoAndStop("gameWin_AG");
			}
		}
		
		// animate all rocks
		public function moveRocks(timeDiff:uint) {
			for(var i:int=rocks.length-1;i>=0;i--) {
				// move the rocks
				var rockSpeed:Number = rockSpeedStart + rockSpeedIncrease*gameLevel;
				rocks[i].rock.x += rocks[i].dx*timeDiff*rockSpeed;
				rocks[i].rock.y += rocks[i].dy*timeDiff*rockSpeed;
				
				// rotate rocks
				rocks[i].rock.rotation += rocks[i].dr*timeDiff*rockSpeed;
				
				// wrap rocks
				
				if ((rocks[i].dx > 0) && (rocks[i].rock.x > 780)) {
					rocks[i].rock.x -= 780;
				}
				if ((rocks[i].dx < 0) && (rocks[i].rock.x < 10)) {
					rocks[i].rock.x += 780;
				}

				if ((rocks[i].dy > 0) && (rocks[i].rock.y > 580)) {
					rocks[i].rock.y -= 580;
				}
				if ((rocks[i].dy < 0) && (rocks[i].rock.y < 10)) {
					rocks[i].rock.y += 580;
				}
			}
		}
		
		public function rockHit(rockNum:uint) {
			// create two smaller rocks
			if (rocks[rockNum].rockType == "Big") {
				playSound(theExplosionSound);
				newRock(rocks[rockNum].rock.x,rocks[rockNum].rock.y,"Medium");
				newRock(rocks[rockNum].rock.x,rocks[rockNum].rock.y,"Medium");
			} else if (rocks[rockNum].rockType == "Medium") {
				playSound(theExplosionSound);
				newRock(rocks[rockNum].rock.x,rocks[rockNum].rock.y,"Small");
				newRock(rocks[rockNum].rock.x,rocks[rockNum].rock.y,"Small");
			}
			// remove original rock
			gameObjects.removeChild(rocks[rockNum].rock);
			rocks.splice(rockNum,1);
			playSound(theExplosionSound);
		}

		// MISSILES
		
		// create a new Missile
		public function newMissile() {
			// create
			var newMissile:Missile = new Missile();
			
			// set direction
			newMissile.dx = Math.cos(Math.PI*ship.rotation/180);
			newMissile.dy = Math.sin(Math.PI*ship.rotation/180);
			
			// placement
			newMissile.x = ship.x + newMissile.dx*shipRadius;
			newMissile.y = ship.y + newMissile.dy*shipRadius;
	
			// add to stage and array
			gameObjects.addChild(newMissile);
			missiles.push(newMissile);
		}
		
		// animate missiles
		public function moveMissiles(timeDiff:uint) {
			for(var i:int=missiles.length-1;i>=0;i--) {
				// move
				missiles[i].x += missiles[i].dx*missileSpeed*timeDiff;
				missiles[i].y += missiles[i].dy*missileSpeed*timeDiff;
				// moved off screen
				if ((missiles[i].x < 0) || (missiles[i].x > _container.width) || (missiles[i].y < 0) || (missiles[i].y > _container.height)) {
					gameObjects.removeChild(missiles[i]);
					delete missiles[i];
					missiles.splice(i,1);
				}
			}
		}
			
		// remove a missile
		public function missileHit(missileNum:uint) {
			gameObjects.removeChild(missiles[missileNum]);
			missiles.splice(missileNum,1);
		}
		
		// GAME INTERACTION AND CONTROL
		
		public function moveGameObjects(event:Event) {
			// get timer difference and animate
			var timePassed:uint = getTimer() - lastTime;
			lastTime += timePassed;
			moveRocks(timePassed);
			if (gameMode != "delay") {
				moveShip(timePassed);
			}
			moveMissiles(timePassed);
			checkCollisions();
		}
		
		// look for missiles colliding with rocks
		public function checkCollisions() {
			// loop through rocks
			rockloop: for(var j:int=rocks.length-1;j>=0;j--) {
				// loop through missiles
				missileloop: for(var i:int=missiles.length-1;i>=0;i--) {
					// collision detection 
					if (Point.distance(new Point(rocks[j].rock.x,rocks[j].rock.y),
							new Point(missiles[i].x,missiles[i].y))
								< rocks[j].rockRadius) {
						
						// remove rock and missile
						rockHit(j);
						missileHit(i);
						
						// add score
						gameScore += 10;
						updateScore();
						
						// break out of this loop and continue next one
						continue rockloop;
					}
				}
				
				// check for rock hitting ship
				if (gameMode == "play_AG") {
					if (shieldOn == false) { // only if shield is off
						if (Point.distance(new Point(rocks[j].rock.x,rocks[j].rock.y),
								new Point(ship.x,ship.y))
									< rocks[j].rockRadius+shipRadius) {
							
							// remove ship and rock
							shipHit();
							rockHit(j);
						}
					}
				}
			}
			
			// all out of rocks, change game mode and trigger more
			if ((rocks.length == 0) && (gameMode == "play_AG")) {
				gameMode = "betweenlevels";
				gameLevel++; // advance a level
				delayTimer = new Timer(2000,1);
				delayTimer.addEventListener(TimerEvent.TIMER_COMPLETE,nextRockWave, false, 0, true);
				delayTimer.start();
			}
		}
		
		public function playSound(soundObject:Object) {
			var channel:SoundChannel = soundObject.play();
		}
		
		public function endGame() {
			// remove all objects and listeners
			_container.removeChild(gameObjects);
			_container.removeChild(scoreObjects);
			gameObjects = null;
			scoreObjects = null;
			_container.removeEventListener(Event.ENTER_FRAME,moveGameObjects);
			_container.removeEventListener(KeyboardEvent.KEY_DOWN,keyDownFunction);
			_container.removeEventListener(KeyboardEvent.KEY_UP,keyUpFunction);
			
			_container.removeEventListener(MouseEvent.MOUSE_DOWN,mouseLeftButtonDown);
			_container.removeEventListener(Event.ENTER_FRAME, onStageEnterFrame);
			_container.removeEventListener(MouseEvent.MOUSE_MOVE,followMouse);
			
			Mouse.show();
		
			_container.gotoAndStop("gameover_AG");
		}
		
	}
}
		
	