

//-------------------- déclaration de variable d'objets et import de librairie----------------------------------

import processing.net.*;

import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.effects.*;
import ddf.minim.signals.*;
import ddf.minim.spi.*;
import ddf.minim.ugens.*;



//-----------------variables menu && network-----------------
Boolean isServer;      //define if server or client

String serverIP = "";  //only used if client
String yourIP = "";

Boolean networkError = false;

Server s; 
Client c;
int port = 2640;
Boolean waitingClient = false;
Boolean firstOKPast = false;
Boolean letItDraw = true;

Boolean menu = true;
Boolean positionning = true;
Boolean play = false;
int menuState = 0;

int[] positionShip1;
int[][] positionShip2;
int[][] positionShip3;
int[][] positionShip4;

int totalSinkPerso = 0;
int totalSinkAdv = 0;


//---------------variables grille && placement bateau--------
int[][] grille_Adver;   
int[][] grille_Perso; 
String caract = "";
int largeurColonne = 0;
int hauteurRangee = 0;

PImage img_bateau11;
PImage img_bateau12;
PImage img_bateau13;
PImage img_bateau14;
PImage background;


String[] tableau_alphabet={"", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J"};

int placement = 0;

int placement11 = 0;
int placement12 = 0;
int placement13 = 0;
int placement14 = 0;

int mode = 0;

float x = 0;
float y = 0;

boolean placement_bon = false;

int k=0;

//---------------variables animations && sons--------

PImage[] flammes = new PImage[33];
PImage[] explosions = new PImage[30];
PImage Start;

int i=0;
int u=0;
int animation=0;
int StartMenu=0;
int couleur=0;
int response;
int sound=0;

boolean launch = false;

Minim minim;
AudioPlayer sound1;
AudioPlayer sound2;
AudioPlayer touche;

//---------------variables déja joué--------
String[] contenuServer;
Table TableServer;
Table TableClient;
int coord_x = 0;
int coord_y = 0;
int cptClick=0;
Boolean print = false;
int turnPrint = 0;
String thingsToPrint ="";



//------------------------------Méthode principale-----------------------------------------

void setup() {
  size(900, 900);
  smooth();
  noStroke();
  background(255);
  frameRate(25);
  textAlign(CENTER); //Important pour moi je sais pas si vous l'utilisez vous ca simplifie la vie ;P
  // SetupTableClient();
  SetupTableServer();


  minim = new Minim(this);
  sound1 = minim.loadFile("sound1.mp3");
  sound2 = minim.loadFile("sound2.mp3");
}

void draw() {
  switch (sound) {
  case 0 :
    // sound1.play();
    //sound2.cue(0);
    break;
  case 1 :
    //sound2.play();
    //sound1.cue(0);
    break;
  }
  if (StartMenu==0) {
    couleurMenu();
  }
  if (StartMenu==1) {
    shipPlacementSetup();
    StartMenu=2;
  }
  if (StartMenu==2) {
    if (menu == true) {
      if (positionning == true) {  //passe à faux quand les 4 bateaux sont placés
        positionningShipDraw(); //afficher les bateaux
      } else {
        menuDraw();  //setup quentin
      }
    } else if (totalSinkPerso == 4) {
      looserLayout();
      stop();
    } else if (totalSinkAdv == 4) {
      winnerLayout();
      stop();
    } else { 
      if (play == true) {
        positionningShipPlay();
        
      } else {
        waitForAnAttack();
      }
      if (print == true) {
          if (turnPrint < 15) {
            //afficher
            fill(0);
            rectMode(CENTER);
            rect(450, 215, 900, 60);
            rectMode(CORNER);
            fill(200, 0, 0);
            textSize(35);
            text(thingsToPrint, 450, 225);
            turnPrint++;
          } else {
            print = false;
            turnPrint = 0;
          }
      }
    }
  }
}

void mousePressed() {
  if (StartMenu==0) {
    if ( ( (mouseX<width/2+100) && (mouseY<height/2+50) && (mouseX>width/2-100) && (mouseY>height/2-50) ) ) {
      launch = true;
      if (launch==true)
      {
        if (sound==0); 
        {
          StartMenu=1; // appuye sur le bouton "Jouer"
        }
      }
    }
  }
  if (menu) {
    if (positionning) {
      positionningShipMousePressed();
    } else {
      menuMousePressed();
    }
  } else {
    if (play) {
      response = trySendingAttack(mouseX, mouseY);
      switch (response) {
      case 500:
        print = true;
        thingsToPrint = "Déjà joué ici, recommencer svp.";
        play =true;
        break;
      case 404:
        println("Tkt no soucis t'as dut missclick a coté des cases t'es pas doué c'est tout. ;)");
        play = true;
        break;
      case 0 : 
        println("Pas de bateau adversaire ici.");
        print = true;
        thingsToPrint = "Dommage, manqué";
        break;
      case 1 : 
        println("GG t'as touché un truc.");
        print = true;
        thingsToPrint = "Yes, quelque chose a été touché";
        break;
      case 2 : 
        println("GG t'as coulé un truc.");
        print = true;
        thingsToPrint = "Bien joué, c'est coulé.";
        totalSinkAdv++;
        break;
      }
    } else {
      //unable to send attack
    }
  }
}

void keyPressed() {
  if (menuState == 1) {
    detectKeyboardInput();
  }
}

void winnerLayout() {
  fill(255);
  rect(0, 0, width, height);
  fill(0);
  textSize(50);
  text("WINNER !", 450, 450);
}
void looserLayout() {
  fill(255);
  rect(0, 0, width, height);
  fill(0);
  textSize(50);
  text("LOOSER !", 450, 450);
}


void SetupTableServer() {
  TableServer = new Table(); // Créé un tableau

  TableServer.clearRows(); //Efface tout ce qu'il y avait dans les lignes 

  TableServer.addColumn("coordonnees x"); // Créé une colonne x
  TableServer.addColumn("coordonnees y"); // Créé une colonne y

  saveTable(TableServer, "data/TableServer.csv"); // Sauvegarde le tableau en .csv avec pour nom "TableServer"
}

void couleurMenu() { // Affiche l'écran titre
  Start = loadImage("StartBackground.png");
  image(Start, 0, 0);
  fill(255-couleur, 0, 0+couleur); //Couleur du texte "Jouer" a l'écran titre
  textSize(80);
  text("Jouer", width/2, height/2);
}

void mouseMoved() // Change la couleur de "Jouer" quand on passe la souris dessus
{
  if ( ( (mouseX<width/2+100) && (mouseY<height/2+50) && (mouseX>width/2-100) && (mouseY>height/2-50) ) ) {
    couleur=255;
  } else {
    couleur=0;
  }
}


//---------------------Fonction perso pour le menu && network --------------------------------


int trySendingAttack(int x, int y) {
  play = false;
  println("\n\n\ntru sending attack");
  int intToReturn = 404;
  for (int i=0; i < 10; i++) {
    for (int j=0; j < 10; j++) {
      x = 40+(i+1)*largeurColonne;
      y = 60+(j+1)*hauteurRangee;
      if (mouseX > x && mouseX < x+largeurColonne && mouseY > y && mouseY< y+hauteurRangee) {
        if (!(AlreadyPlay(i, j))) { // Sauvegarde la position de l'attaque
          if (isServer) {
            s.write(i+","+j+"\n");
            println("sending attack at x:"+i+"   y:"+j);
            while (s.available() == null) {
              delay(250);
            }
            c = s.available();
          } else {
            c.write(i+","+j+"\n");
            println("sending attack at x:"+i+"   y:"+j);
            while (c.available() <= 0) {
              delay(250);
            }
          }
          if (c != null) {
            String input = c.readString(); 
            println(input);
            input = input.substring(0, input.indexOf("\n"));
            println("The response is: "+input);
            intToReturn = int(input);
          }
        } else {
          intToReturn = 500;
        }
      }
    }
  }
  return intToReturn;
}

Boolean AlreadyPlay(int i, int j) {
  coord_x = i;
  coord_y = j;
  Boolean boolToReturn = false;

  TableServer = loadTable("TableServer.csv", "header"); // On charge la Table
  String[] lignes = loadStrings("TableServer.csv"); // On charge les lignes
  for (int w=1; w <= cptClick; w++) { // Ecrit ce qu'il y a dans les lignes pour debug
    println("\n\n\nligne n°"+w+":"+lignes[w]);

    contenuServer=loadStrings("TableServer.csv"); // Charge ce qu'il y a dans les lignes
    String alreadyPlay = lignes[w]; // Recupere ce qu'il y a dans les lignes
    println("alreadyPlay="+alreadyPlay);
    int[] XY = int(split(alreadyPlay, ","));
    println("i,j="+i+","+j);
    if (XY[0]==i && XY[1]==j) {// Censé comparé ce qu'il y a dans les lignes et la case sur laquel on appuie
      println("déja joué ici");
      boolToReturn = true;
    } else {
      println("pas encore joué");
    }
  }
  TableServer = loadTable("TableServer.csv", "header"); // Charge la Table serveur

  TableRow newRow = TableServer.addRow(); // Créé une ligne 
  newRow.setInt("coordonnees x", coord_x); // dans la colonne x, inscrire x
  newRow.setInt("coordonnees y", coord_y); // dans la colonne y, inscrire y

  saveTable(TableServer, "data/TableServer.csv"); // sauvegarder
  cptClick++; // Incrémenter à chaque click
  return boolToReturn;
}


void waitForAnAttack() {
  if (!letItDraw) {
    if (isServer) {
      while (s.available() == null) {
        delay(250);
      }
      c = s.available();
    } else {

      while (c.available() <= 0) {
        delay(250);
      }
    } 
    if (c!= null) {
      String input = c.readString(); 
      input = input.substring(0, input.indexOf("\n"));
      println(input);
      if (firstOKPast) {
        int coordinates[] = int(split(input, ','));
        println("\n\n\n\nAttack receive at x:"+coordinates[0]+"   y:"+coordinates[1]);
        int MTOrCToRespond = MTOrC(coordinates[0], coordinates[1]);
        if (isServer) {
          s.write(MTOrCToRespond+"\n");
        } else {
          c.write(MTOrCToRespond+"\n");
        }
        if (MTOrCToRespond == 2) {
          totalSinkPerso++;
        }
        play = true;
        letItDraw = true;
      } else {
        firstOKPast = true;
      }
    }
  } else {
    fill(0);
    rectMode(CENTER);
    rect(450, 440, 900, 60);
    rectMode(CORNER);
    fill(200, 0, 0);
    textSize(35);
    text("En attente de l'attaque de l'autre joueur.", 450, 450);
    letItDraw = false;
  }
}




int MTOrC(int x, int y) {
  int intToReturn = 0;
  int shootPositionResult = grille_Perso[x][y];
  int shipCode = (shootPositionResult - (shootPositionResult % 10 ))/10 ;
  println("bateau de :"+shipCode);
  int numberAlreadyTouched = 0;
  switch (shipCode) {
  case 1:
    grille_Perso[x][y] = 12;
    intToReturn = 2;
    break;
  case 2:
    grille_Perso[x][y] = 21;
    intToReturn = 1;
    for (int i=0; i < positionShip2.length; i++) {
      int magicCalculus = grille_Perso[positionShip2[i][0]][positionShip2[i][1]]%10;
      if (magicCalculus == 1 ) {
        numberAlreadyTouched++;
      }
    }
    if (numberAlreadyTouched == 2) {
      intToReturn = 2;
      for (int i=0; i < positionShip2.length; i++) {
        grille_Perso[positionShip2[i][0]][positionShip2[i][1]] = 22;
      }
    }
    break;
  case 3:
    grille_Perso[x][y] = 31;
    intToReturn = 1;
    for (int i=0; i < positionShip3.length; i++) {
      int magicCalculus = grille_Perso[positionShip3[i][0]][positionShip3[i][1]]%10;
      if (magicCalculus == 1 ) {
        numberAlreadyTouched++;
      }
    }
    if (numberAlreadyTouched == 3) {
      intToReturn = 2;
      for (int i=0; i < positionShip3.length; i++) {
        grille_Perso[positionShip3[i][0]][positionShip3[i][1]] = 32;
      }
    }
    break;
  case 4:
    grille_Perso[x][y] = 41;
    intToReturn = 1;
    for (int i=0; i < positionShip4.length; i++) {
      int magicCalculus = grille_Perso[positionShip4[i][0]][positionShip4[i][1]]%10;
      if (magicCalculus == 1 ) {
        numberAlreadyTouched++;
      }
    }
    if (numberAlreadyTouched == 4) {
      intToReturn = 2;
      for (int i=0; i < positionShip4.length; i++) {
        grille_Perso[positionShip4[i][0]][positionShip4[i][1]] = 32;
      }
    }
    break;
  }
  return intToReturn;
}





void detectKeyboardInput() {
  println(key);
  if (keyCode == 8 ) {
    if (serverIP.length() >= 1) {
      serverIP = serverIP.substring(0, serverIP.length()-1);
    }
  } else if (key != 10) {
    serverIP += key;
  }
}
void menuMousePressed() {
  switch (menuState) {
  case 0:
    if (mouseX<387 && mouseX>287 && mouseY<463 && mouseY>437) {
      isServer = true;
      menuState += 2;
      try {
        s = new Server(this, port);  // Start a simple server on a port
        yourIP = Server.ip();
      } 
      catch (Exception e) {
        networkError = true;
      }
    } else if (mouseX<597 && mouseX>527 && mouseY<463 && mouseY>437) {
      isServer = false;
      menuState += 1;
    }
    break;
  case 1:
    if (mouseX<568 && mouseX>338 && mouseY<624 && mouseY>568) {
      try {
        c = new Client(this, serverIP, port); // start a simple client
      } 
      catch (Exception e) {
        networkError = true;
      }
      menuState += 1;
    }
    break;
  }
}
void menuDraw() {
  background(204);
  fill(255);
  strokeWeight(4);
  stroke(0);
  rect(112, 112, 675, 563);
  switch (menuState) {
  case 0 :
    fill(0);
    textSize(15);
    text("Vos placements de bateaux ont bien été enregistrés\nMerci de lancer d'abord le serveur.", 450, 225);
    textSize(30);
    text("Sélectionner celui qui vous correspond :", 450, 338);
    textSize(25);
    text("Serveur", 337, 450);
    text("Client", 562, 450);
    break;
  case 1 :
    fill(0);
    textSize(35);
    text("Taper directement votre IP:", 450, 225);
    textSize(18);
    text("Pas besoin de selectionner la zone,\n adresse IP avec des point s'il vous plait", 450, 350);
    rect(225, 437, 450, 25);
    fill(255);
    textSize(20);
    text(serverIP, 450, 450);
    fill(0);
    rect(338, 568, 225, 56);
    fill(200, 0, 0);
    textSize(25);
    text("Let's go!", 450, 596);
    break;
  case 2 :
    if (!networkError) { 
      fill(200, 0, 0);
      textSize(40);
      text("En attente de l'autre joueur…", 450, 225);
      fill(0);
      if (isServer) {
        fill(0);
        textSize(20);
        text("votre IP est: "+yourIP, 450, 450);
        c = s.available();
        println(c);
        if (waitingClient == true) {
          delay(1000);
        }
        if (c != null) {
          menu = false;
          println("server started and received first data");
          play = false;
          noStroke();
          background(255);
          positionningShipPlay();
        } else {
          waitingClient = true;
        }
      } else {
        c.write("OK\n");
        menu = false;
        play = true;
        firstOKPast = true;
        noStroke();
        background(255);
        positionningShipPlay();
      }
    } else {
      fill(255);
      strokeWeight(4);
      stroke(0);
      rect(112, 112, 675, 563);
      fill(200, 0, 0);
      text("Une erreur est survenue \n merci de relancer le jeu et réessayer.", 450, 450);
    }
    break;
  }
}

void registerShipPlacement() {
  positionShip1 = new int[4];
  positionShip2 = new int[2][2];
  positionShip3 = new int[3][2];
  positionShip4 = new int[4][2];
  int alreadyRegister2 = 0;
  int alreadyRegister3 = 0;
  int alreadyRegister4 = 0;
  for (int i=0; i < 10; i++) {
    for (int j=0; j < 10; j++) {
      if (grille_Perso[i][j] != 0) {
        println(grille_Perso[i][j]);
        int shipCode = grille_Perso[i][j] / 10;
        println("bateau de " + str(shipCode) + "      x:"+ str(i) + " y:" + str(j));
        switch (shipCode) {
        case 1:
          positionShip1[0] = i ;
          positionShip1[1] = j ;
          break;
        case 2:
          positionShip2[alreadyRegister2][0] = i ;
          positionShip2[alreadyRegister2][1] = j ;
          alreadyRegister2++;
          break;
        case 3:
          positionShip3[alreadyRegister3][0] = i ;
          positionShip3[alreadyRegister3][1] = j ;
          alreadyRegister3++;
          break;
        case 4:
          positionShip4[alreadyRegister4][0] = i ;
          positionShip4[alreadyRegister4][1] = j ;
          alreadyRegister4++;
          break;
        }
      }
    }
  }
}



//----------------fonction perso pour le placement des bateau------------------

void positionningShipPlay() {

  fill(255);
  rect(0, 0, width, height);

  tint(200, 200, 200, 200);
  image(background, 92, 93, 508, 318);
  image(background, 92, 543, 508, 318);

  fill(200, 0, 0);
  rect(0, (height/2)-5, width, 5); //Rectangle pour séparer les 2 grilles

  rect(345, 4, 210, 30); //Rectangle en haut pour le texte : Grille Adversaire
  fill(0);
  textSize(25);
  text("Grille Adversaire", width/2, 25);

  fill(200, 0, 0);
  rect(390, 5+height/2, 120, 30);  //Rectangle en bas(milieu) pour le texte : Ma grille
  fill(0);
  textSize(25);
  text("Ma grille", 450, 25+height/2);

  textSize(15);

  largeurColonne = (width/11)-30; //Initialisation des variables
  hauteurRangee = (height/21)-10;

  for (int i=0; i < 10; i++) {                 //Doucle bloucle, pour la création du plateau, affactetiondes variable au cases, affichage des variables dans les cases, affichage des numéros au dessus (bande noire)
    for (int j=0; j < 10; j++) {
      //Grille_Adver :
      fill(200);
      x = 40+largeurColonne+i*largeurColonne;
      y = 60+hauteurRangee+j*hauteurRangee;
      rect(x+largeurColonne-1, y-1, 2, hauteurRangee);  //Dessin bordure des cases pour le plateau
      rect(x-1, y+hauteurRangee-1, largeurColonne, 2);  //Dessin bordure des cases pour le plateau

      //Grille_Perso:
      fill(200);
      y = y+(height/2);
      rect(x+largeurColonne-1, y-1, 2, hauteurRangee);  //Dessin bordure des cases pour le plateau
      rect(x-1, y+hauteurRangee-1, largeurColonne, 2);  //Dessin bordure des cases pour le plateau
    }
  }

  for (int i=1; i<11; i++) {
    x = 40+i*largeurColonne;

    //Grille_Adver :
    y = 60;
    caseAbscisse(i, x, y);

    //Grille_Perso :
    y = y+(height/2);
    caseAbscisse(i, x, y);
  }

  for (int i=1; i < 11; i++) {       //Boucle pour placer les lettres sur les côtés (des 2 grilles)

    //Grille_Adver :
    y = 60+i*hauteurRangee;
    caseOrdonnee(i, y);

    //Grille_Perso :
    y = y+(height/2);
    caseOrdonnee(i, y);
  }

  for (int i=0; i < 10; i++) {  //Doucle bloucle, pour la création du plateau, affactetiondes variable au cases, affichage des variables dans les cases, affichage des numéros au dessus (bande noire)
    for (int j=0; j < 10; j++) {

      float x = 40+largeurColonne+i*largeurColonne;
      float y = (height/2)+60+hauteurRangee+j*hauteurRangee;

      switch (grille_Perso[i][j]) {
      case 10:

        fill(255, 0, 0);
        rect(x, y, largeurColonne-1, hauteurRangee-1);  //Dessin des cases pour le plateau
        break;

      case 20:
        fill(0, 255, 0);
        rect(x, y, largeurColonne-1, hauteurRangee-1);  //Dessin des cases pour le plateau
        break;

      case 30:

        fill(0, 0, 255);
        rect(x, y, largeurColonne-1, hauteurRangee-1);  //Dessin des cases pour le plateau
        break;

      case 40:

        fill(100, 100, 100);
        rect(x, y, largeurColonne-1, hauteurRangee-1);  //Dessin des cases pour le plateau
        break;
      }
    }
  }
}

void shipPlacementSetup() {
  background(255);

  img_bateau11 = loadImage("bateau11.png");
  img_bateau12 = loadImage("bateau12.png");
  img_bateau13 = loadImage("bateau13.png");
  img_bateau14 = loadImage("bateau14.png");
  background = loadImage("background.png");

  tint(200, 200, 200, 200);

  largeurColonne = (width/11)-30; //Initialisation des variables
  hauteurRangee = (height/21)-10;

  image(background, 40+largeurColonne, 60+hauteurRangee, largeurColonne*10, hauteurRangee*10);
  image(background, 40+largeurColonne, 60+hauteurRangee+width/2, largeurColonne*10, hauteurRangee*10);

  fill(200, 0, 0);
  rect(0, (height/2)-5, width, 5); //Rectangle pour séparer les 2 grilles

  rect(345, 4, 210, 30); //Rectangle en haut pour le texte : Grille Adversaire
  fill(0);
  textSize(25);
  text("Grille Adversaire", width/2, 25);

  fill(200, 0, 0);
  rect(390, 5+height/2, 120, 30);  //Rectangle en bas(milieu) pour le texte : Ma grille
  fill(0);
  textSize(25);
  text("Ma grille", 450, 25+height/2);

  grille_Adver = new int[10][10];  //10 cases en x et 10 en y
  grille_Perso = new int[10][10];  //Déclaration des tailles des grilles (10 cases en x et 10 en y)

  // valeur cases
  textSize(15);


  for (int i=0; i < 10; i++) {                 //Doucle bloucle, pour la création du plateau, affactetiondes variable au cases, affichage des variables dans les cases, affichage des numéros au dessus (bande noire)
    for (int j=0; j < 10; j++) {
      grille_Adver[i][j] = 00;                          // Affectation au cases de la valeur "00" car l'initialisation, les cases sont vide
      grille_Perso[i][j] = 00;

      //Grille_Adver :
      fill(200);
      x = 40+largeurColonne+i*largeurColonne;
      y = 60+hauteurRangee+j*hauteurRangee;
      rect(x+largeurColonne-1, y-1, 2, hauteurRangee);  //Dessin bordure des cases pour le plateau
      rect(x-1, y+hauteurRangee-1, largeurColonne, 2);  //Dessin bordure des cases pour le plateau

      //fill(0);
      //caract = str(grille_Adver[i][j]);
      //text(caract, x+largeurColonne/2, y+hauteurRangee/2); //Ecriture de la valeur de la case, dans la case (Grille 1)

      //Grille_Perso:
      fill(200);
      y = y+(height/2);
      rect(x+largeurColonne-1, y-1, 2, hauteurRangee);  //Dessin bordure des cases pour le plateau
      rect(x-1, y+hauteurRangee-1, largeurColonne, 2);  //Dessin bordure des cases pour le plateau

      //fill(0);
      //caract = str(grille_Perso[i][j]);
      //text(caract, x+largeurColonne/2, y+hauteurRangee/2);  //Ecriture de la valeur de la case, dans la case (Grille_Perso)
    }
  }

  for (int i=1; i<11; i++) {
    x = 40+i*largeurColonne;

    //Grille_Adver :
    y = 60;
    caseAbscisse(i, x, y);

    //Grille_Perso :
    y = y+(height/2);
    caseAbscisse(i, x, y);
  }

  for (int i=1; i < 11; i++) {       //Boucle pour placer les lettres sur les côtés (des 2 grilles)

    //Grille_Adver :
    y = 60+i*hauteurRangee;
    caseOrdonnee(i, y);

    //Grille_Perso :
    y = y+(height/2);
    caseOrdonnee(i, y);
  }

  fill(225);
  rect(630, 510, 240, 350);  //Rectangle gris en bas à gauche pour les "consignes"
  fill(0);
  text("Placer vos bateaux :", 750, 540);
  tint(255, 255, 255, 255);
  image(img_bateau11, 725, 560, largeurColonne, hauteurRangee);
  image(img_bateau12, 700, 630, 2*largeurColonne, hauteurRangee);
  image(img_bateau13, 674, 708, 3*largeurColonne, hauteurRangee);
  image(img_bateau14, 649, 782, 4*largeurColonne, hauteurRangee);
}


void caseAbscisse(int i, float x, float y) {
  fill(0);
  rect(x, y, largeurColonne-1, hauteurRangee-1 );  //cases noir du contour
  fill(255, 0, 0);
  text(i, x+largeurColonne/2, y+hauteurRangee/2);  //Valeur des cases (1/2/3/...)
}


void caseOrdonnee(int i, float y) {
  String lettre = tableau_alphabet[i];
  fill(0);
  rect(40, y, largeurColonne-1, hauteurRangee-1 );
  fill(255, 0, 0);
  text(lettre, 40+largeurColonne/2, y+hauteurRangee/1.5);
}

void positionningShipDraw() {

  fill(255);
  rect(700, 0, 200, 50);
  fill(0);
  textSize(20);
  text("Musique suivante", 800, 25);


  for (int i=0; i < 10; i++) {  //Doucle bloucle, pour la création du plateau, affactetiondes variable au cases, affichage des variables dans les cases, affichage des numéros au dessus (bande noire)
    for (int j=0; j < 10; j++) {

      float x = 40+largeurColonne+i*largeurColonne;
      float y = (height/2)+60+hauteurRangee+j*hauteurRangee;

      switch (grille_Perso[i][j]) {
      case 10:

        fill(255, 0, 0);
        rect(x, y, largeurColonne-1, hauteurRangee-1);  //Dessin des cases pour le plateau
        break;

      case 20:
        fill(0, 255, 0);
        rect(x, y, largeurColonne-1, hauteurRangee-1);  //Dessin des cases pour le plateau
        break;

      case 30:

        fill(0, 0, 255);
        rect(x, y, largeurColonne-1, hauteurRangee-1);  //Dessin des cases pour le plateau
        break;

      case 40:

        fill(100, 100, 100);
        rect(x, y, largeurColonne-1, hauteurRangee-1);  //Dessin des cases pour le plateau
        break;
      }
    }
  }
}


void positionningShipMousePressed() {

  if ( ( (mouseX<width) && (mouseY<75) && (mouseX>700) && (mouseY>0) ) ) {
    sound++;
    println(sound);
    if (sound>=2) {
      sound=0;
    }
  }


  if (mouseX>725 && mouseX<725+largeurColonne && mouseY>560 && mouseY<560+hauteurRangee) {
    if (placement11==0) {
      placement11 = 1;
      placement12 = 0;
      placement13 = 0;
      placement14 = 0;
      fill(225);
      rect(630, 510, 240, 45);
      fill(0);
      text("Choisissez les cases du bateau", 750, 530);
      text("(1 case pour celui-ci)", 750, 550);
    }
  }

  if (mouseX>700 && mouseX<700+2*largeurColonne && mouseY>630 && mouseY<630+hauteurRangee) {
    if (placement12==0) {
      placement11 = 0;
      placement12 = 1;
      placement13 = 0;
      placement14 = 0;
      fill(225);
      rect(630, 510, 240, 45);
      fill(0);
      text("Choisissez les cases du bateau", 750, 530);
      text("(2 cases pour celui-ci)", 750, 550);
    }
  }

  if (mouseX>674 && mouseX<674+3*largeurColonne && mouseY>708 && mouseY<708+hauteurRangee && placement13==0) {
    placement11 = 0;
    placement12 = 0;
    placement13 = 1;
    placement14 = 0;
    fill(225);
    rect(630, 510, 240, 45);
    fill(0);
    text("Choisissez les cases du bateau", 750, 530);
    text("(3 cases pour celui-ci)", 750, 550);
  }

  if (mouseX>649 && mouseX<649+4*largeurColonne && mouseY>782 && mouseY<782+hauteurRangee && placement14==0) {
    placement11 = 0;
    placement12 = 0;
    placement13 = 0;
    placement14 = 1;
    fill(225);
    rect(630, 510, 240, 45);
    fill(0);
    text("Choisissez les cases du bateau", 750, 530);
    text("(4 cases pour celui-ci)", 750, 550);
  }



  if (placement11 == 1) {
    placement11 ();
  }

  if (placement12 == 2) {
    placement12_2 ();
  }
  if (placement12 == 1) {
    placement12_1 ();
  }


  if (placement13 == 3) {
    placement13_3 ();
  }

  if (placement13 == 2) {
    placement13_2 ();
  }

  if (placement13 == 1) {
    placement13_1 ();
  }

  if (placement14 == 4) {
    placement14_4 ();
  }


  if (placement14 == 3) {
    placement14_3 ();
  }


  if (placement14 == 2) {
    placement14_2 ();
  }

  if (placement14 == 1) {
    placement14_1 ();
  }


  if (placement == 4) {
    fill(225);
    rect(630, 510, 240, 45);
    fill(0);
    text("Tous les bateaux sont placés", 750, 540);
    positionning = false;
    registerShipPlacement();
  }
}


void valider_placement_1(int i, int j) {

  placement_bon = false;

  if (grille_Perso[i][j] == 0) {
    placement_bon = true;
  } else { 
    println("erreur case prise");
  }
}


void placement11 () {

  for (int i=0; i <10; i++) {
    for (int j=0; j <10; j++) {
      if (mouseX>40+largeurColonne+i*largeurColonne && mouseX<40+2*largeurColonne+i*largeurColonne && mouseY>+(height/2)+60+hauteurRangee+j*hauteurRangee && mouseY<+(height/2)+60+2*hauteurRangee+j*hauteurRangee) {
        valider_placement_1 (i, j);
        if (placement_bon == true)
        {
          placer11_1 (i, j);
        }
      }
    }
  }
}

void placement12_1 () {
  for (int i=0; i <10; i++) {
    for (int j=0; j <10; j++) {
      if (mouseX>40+largeurColonne+i*largeurColonne && mouseX<40+2*largeurColonne+i*largeurColonne && mouseY>(height/2)+60+hauteurRangee+j*hauteurRangee && mouseY<(height/2)+60+2*hauteurRangee+j*hauteurRangee) {
        valider_placement_1 (i, j);
        if (placement_bon == true) {
          placer12_1 (i, j);
        }
      }
    }
  }
}

void placement12_2 () {
  for (int i=0; i <10; i++) {
    for (int j=0; j <10; j++) {
      if (mouseX>40+largeurColonne+i*largeurColonne && mouseX<40+2*largeurColonne+i*largeurColonne && mouseY>+(height/2)+60+hauteurRangee+j*hauteurRangee && mouseY<(height/2)+60+2*hauteurRangee+j*hauteurRangee) {
        valider_placement_2 (20, i, j);
        if (placement_bon == true) {
          placer12_2 (i, j);
        }
      }
    }
  }
}

void placement13_1 () {
  for (int i=0; i <10; i++) {
    for (int j=0; j <10; j++) {
      if (mouseX>40+largeurColonne+i*largeurColonne && mouseX<40+2*largeurColonne+i*largeurColonne && mouseY>(height/2)+60+hauteurRangee+j*hauteurRangee && mouseY<(height/2)+60+2*hauteurRangee+j*hauteurRangee) {
        valider_placement_1 (i, j);
        if (placement_bon == true) {
          placer13_1 (i, j);
        }
      }
    }
  }
}

void placement13_2 () {

  for (int i=0; i <10; i++)
  {
    for (int j=0; j <10; j++)
    {
      if (mouseX>40+largeurColonne+i*largeurColonne && mouseX<40+2*largeurColonne+i*largeurColonne && mouseY>(height/2)+60+hauteurRangee+j*hauteurRangee && mouseY<(height/2)+60+2*hauteurRangee+j*hauteurRangee)
      {
        valider_placement_2 (30, i, j);
        if (placement_bon == true)
        {
          placer13_2 (i, j);
        }
      }
    }
  }
}

void placement13_3 () {
  for (int i=0; i <10; i++)
  {
    for (int j=0; j <10; j++)
    {
      if (mouseX>40+largeurColonne+i*largeurColonne && mouseX<40+2*largeurColonne+i*largeurColonne && mouseY>(height/2)+60+hauteurRangee+j*hauteurRangee && mouseY<(height/2)+60+2*hauteurRangee+j*hauteurRangee)
      {
        valider_placement_3 (30, i, j);
        if (placement_bon == true)
        {
          placer13_3 (i, j);
        }
      }
    }
  }
}

void placement14_1 () {
  for (int i=0; i <10; i++) {
    for (int j=0; j <10; j++) {
      if (mouseX>40+largeurColonne+i*largeurColonne && mouseX<40+2*largeurColonne+i*largeurColonne && mouseY>(height/2)+60+hauteurRangee+j*hauteurRangee && mouseY<(height/2)+60+2*hauteurRangee+j*hauteurRangee) {
        valider_placement_1 (i, j);
        if (placement_bon == true) {
          placer14_1 (i, j);
        }
      }
    }
  }
}

void placement14_2 () {
  for (int i=0; i <10; i++) {
    for (int j=0; j <10; j++) {
      if (mouseX>40+largeurColonne+i*largeurColonne && mouseX<40+2*largeurColonne+i*largeurColonne && mouseY>(height/2)+60+hauteurRangee+j*hauteurRangee && mouseY<(height/2)+60+2*hauteurRangee+j*hauteurRangee) {
        valider_placement_2 (40, i, j);
        if (placement_bon == true) {
          placer14_2 (i, j);
        }
      }
    }
  }
}

void placement14_3 () {
  for (int i=0; i <10; i++) {
    for (int j=0; j <10; j++) {
      if (mouseX>40+largeurColonne+i*largeurColonne && mouseX<40+2*largeurColonne+i*largeurColonne && mouseY>(height/2)+60+hauteurRangee+j*hauteurRangee && mouseY<(height/2)+60+2*hauteurRangee+j*hauteurRangee) {
        valider_placement_3 (40, i, j);
        if (placement_bon == true) {
          placer14_3 (i, j);
        }
      }
    }
  }
}

void placement14_4 () {
  for (int i=0; i <10; i++) {
    for (int j=0; j <10; j++) {
      if (mouseX>40+largeurColonne+i*largeurColonne && mouseX<40+2*largeurColonne+i*largeurColonne && mouseY>(height/2)+60+hauteurRangee+j*hauteurRangee && mouseY<(height/2)+60+2*hauteurRangee+j*hauteurRangee) {
        valider_placement_4 (40, i, j);
        if (placement_bon == true) {
          placer14_4 (i, j);
        }
      }
    }
  }
}


void valider_placement_2 (int ref_bateau, int i, int j) {

  placement_bon = false;
  if (grille_Perso[i][j] == 0) {
    int k=i+1;

    if (k<10 && grille_Perso[k][j] == ref_bateau) {
      placement_bon = true;
    }

    k=i-1;
    if (k>-1 && grille_Perso[k][j] == ref_bateau) { 
      placement_bon = true;
    }

    k=j+1;
    if (k<10 && grille_Perso[i][k] == ref_bateau) {
      placement_bon = true;
    }

    k=j-1;
    if (k>-1 && grille_Perso[i][k] == ref_bateau) {
      placement_bon = true;
    }
  } else { 
    println("erreur case prise, ou il faut que les cases du bateau soit sur la même ligne ou colonne");
  }
}



void valider_placement_3(int ref_bateau, int i, int j) {
  placement_bon = false;

  if (grille_Perso[i][j] == 0) {

    int k=i+1;
    if (k<10 && grille_Perso[k][j] == ref_bateau) {

      k=i+2;
      if (k<10 && grille_Perso[k][j] == ref_bateau) {
        placement_bon = true;
      }
    }

    k=i-1;
    if (k>-1 && grille_Perso[k][j] == ref_bateau) {

      k=i-2;
      if (k>-1 && grille_Perso[k][j] == ref_bateau) {
        placement_bon = true;
      }
    }

    k=j+1;
    if (k<10 && grille_Perso[i][k] == ref_bateau) {

      k=j+2;
      if (k<10 && grille_Perso[i][k] == ref_bateau) {
        placement_bon = true;
      }
    }

    k=j-1;
    if (k>-1 && grille_Perso[i][k] == ref_bateau) {

      k=j-2;
      if (k>-1 && grille_Perso[i][k] == ref_bateau) {
        placement_bon = true;
      }
    }
  } else { 
    println("erreur case prise, ou il faut que les cases du bateau soit sur la même ligne ou colonne");
  }
}

void valider_placement_4(int ref_bateau, int i, int j) {
  placement_bon = false;

  if (grille_Perso[i][j] == 0) {

    int k=i+1;
    if (k<10 && grille_Perso[k][j] == ref_bateau) {

      k=i+2;
      if (k<10 && grille_Perso[k][j] == ref_bateau) {

        k=i+3;
        if (k<10 && grille_Perso[k][j] == ref_bateau) {
          placement_bon = true;
        }
      }
    }

    k=i-1;
    if (k>-1 && grille_Perso[k][j] == ref_bateau) {

      k=i-2;
      if (k>-1 && grille_Perso[k][j] == ref_bateau) {

        k=i-3;
        if (k>-1 && grille_Perso[k][j] == ref_bateau) {
          placement_bon = true;
        }
      }
    }

    k=j+1;
    if (k<10 && grille_Perso[i][k] == ref_bateau) {

      k=j+2;
      if (k<10 && grille_Perso[i][k] == ref_bateau) {

        k=j+3;
        if (k<10 && grille_Perso[i][k] == ref_bateau) {
          placement_bon = true;
        }
      }
    }

    k=j-1;
    if (k>-1 && grille_Perso[i][k] == ref_bateau) {

      k=j-2;
      if (k>-1 && grille_Perso[i][k] == ref_bateau) {

        k=j-3;
        if (k>-1 && grille_Perso[i][k] == ref_bateau) {
          placement_bon = true;
        }
      }
    }
  } else { 
    println("erreur case prise, ou il faut que les cases du bateau soit sur la même ligne ou colonne");
  }
}
void placer11_1 (int i, int j)
{
  grille_Perso[i][j] = 10;
  placement11 = 2;
  placement ++;
  fill(225);
  rect(630, 60, 240, 50);
  fill(0);
  text("Bateau 1 placé :", 750, 80);
  i++;
  j++;
  String y=tableau_alphabet[j];
  text(i+" / "+y, 750, 100);

  fill(200, 0, 0);
  rect(725, 555, largeurColonne, 5);
  rect(725, 560+hauteurRangee, largeurColonne, 5);
  rect(720, 555, 5, hauteurRangee+10);
  rect(725+largeurColonne, 555, 5, hauteurRangee+10);
}

void placer12_1 (int i, int j)
{
  grille_Perso[i][j] = 20;
  placement12 = 2;
  fill(225);
  rect(630, 115, 240, 60);
  fill(0);
  text("Bateau 2 placé :", 750, 135);
  i++;
  j++;
  String y=tableau_alphabet[j];
  text(i+" / "+y, 750, 155);
}

void placer12_2 (int i, int j)
{
  grille_Perso[i][j] = 20;
  placement12 = 3;
  placement++;
  fill(0);
  i++;
  j++;
  String y=tableau_alphabet[j];
  text(i+" / "+y, 750, 170);
  fill(200, 0, 0);
  rect(700, 625, 2*largeurColonne, 5);
  rect(700, 630+hauteurRangee, 2*largeurColonne, 5);
  rect(695, 625, 5, hauteurRangee+10);
  rect(700+2*largeurColonne, 625, 5, hauteurRangee+10);
}

void placer13_1 (int i, int j)
{
  grille_Perso[i][j] = 30;
  placement13 = 2;
  fill(225);
  rect(630, 180, 240, 80);
  fill(0);
  text("Bateau 3 placé :", 750, 200);
  i++;
  j++;
  String y=tableau_alphabet[j];
  text(i+" / "+y, 750, 220);
}

void placer13_2 (int i, int j)
{
  grille_Perso[i][j] = 30;
  placement13 = 3;
  fill(0);
  i++;
  j++;
  String y=tableau_alphabet[j];
  text(i+" / "+y, 750, 235);
}

void placer13_3 (int i, int j)
{
  grille_Perso[i][j] = 30;
  placement13 = 4;
  placement++;
  fill(0);
  i++;
  j++;
  String y=tableau_alphabet[j];
  text(i+" / "+y, 750, 250);
  fill(200, 0, 0);
  rect(674, 703, 3*largeurColonne, 5);
  rect(674, 708+hauteurRangee, 3*largeurColonne, 5);
  rect(669, 703, 5, hauteurRangee+10);
  rect(674+3*largeurColonne, 703, 5, hauteurRangee+10);
}

void placer14_1 (int i, int j)
{
  grille_Perso[i][j] = 40;
  placement14 = 2;
  fill(225);
  rect(630, 265, 240, 90);
  fill(0);
  text("Bateau 4 placé :", 750, 285);
  i++;
  j++;
  String y=tableau_alphabet[j];
  text(i+" / "+y, 750, 305);
}

void placer14_2 (int i, int j)
{
  grille_Perso[i][j] = 40;
  placement14 = 3;
  fill(0);
  i++;
  j++;
  String y=tableau_alphabet[j];
  text(i+" / "+y, 750, 320);
}

void placer14_3 (int i, int j)
{
  grille_Perso[i][j] = 40;
  placement14 = 4;
  fill(0);
  i++;
  j++;
  String y=tableau_alphabet[j];
  text(i+" / "+y, 750, 335);
}

void placer14_4 (int i, int j)
{
  grille_Perso[i][j] = 40;
  placement14 = 5;
  placement++;
  fill(0);
  i++;
  j++;
  String y=tableau_alphabet[j];
  text(i+" / "+y, 750, 350);
  fill(200, 0, 0);
  rect(649, 777, 4*largeurColonne, 5);
  rect(649, 782+hauteurRangee, 4*largeurColonne, 5);
  rect(645, 777, 5, hauteurRangee+10);
  rect(649+4*largeurColonne, 777, 5, hauteurRangee+10);
}

void stop() {
  minim.stop();
  super.stop();
}
