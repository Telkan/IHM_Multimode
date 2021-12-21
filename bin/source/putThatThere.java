import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import fr.dgac.ivy.*; 
import java.awt.Point; 

import fr.dgac.ivy.*; 
import fr.dgac.ivy.tools.*; 
import gnu.getopt.*; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class putThatThere extends PApplet {



// data
ArrayList<Forme> formes;
Ivy bus;
OrderDraw order;
float confidenceThreshold =  0.7f;
FSM mae;
//SRA decryption key 
private int ACTION			= 0;
private int WHERE			= 1;
private int FORM			= 2;
private int COLOR			= 3;
private int LOCALISATION	= 4;
private int CONFIDENCE		= 5;

int formSelected = -1;

PFont f;                           
Point posSelected;

public void setup()
{
	
	surface.setResizable(true);
	background(255);
	formes = new ArrayList<Forme>();
	mae = FSM.WAIT_FOR_ORDER;
	setupIvy();

	delay(1000);	
	try {bus.sendMsg("ppilot5 Say='Hello, welcome to this multimodal drawing system. Please check that the Icar module is activated as well as sra5. For voice commands, say for example and with a french accent : Créer un triangle rouge EC. When your shape is ready, just say okay'");	} catch (Exception e) {}
	f = createFont("Arial",16,true);
	textFont(f,16);                 
	fill(0);  
	

}

public void draw()
{
	switch (mae) {
		case WAIT_FOR_ORDER:
			displayAll();
			break;
		case DRAW:
			displayAll();
			text("Drawing",0,height-5);
			if(order != null){
				order.createPreview();
			}
			break;
		case MOVE:
			displayAll();
      		fill(0);
			text("Moving",0,height-5);  
			if(formSelected != -1){
				posSelected = formes.get(formSelected).getLocation();
				circle((float)posSelected.getX(), (float)posSelected.getY(), 10.f);
			} 
			break;
		case DELETE:
			displayAll();
			fill(0);
			text("Deleting",0,height-5);
			break;
		default :
			mae = FSM.WAIT_FOR_ORDER;	
			break;
	}
}




public void displayAll(){
	background(255);
	int i = 0;
	while(i < formes.size()){
		formes.get(i).update();
		i++;
	}

}

public void setupIvy(){
	//Setup Ivy and all the listeners 
	try
	{
		bus = new Ivy("multimod", " Ready to draw some things!", null);
		bus.start("127.255.255.255:2010");
		bus.bindMsg("^sra5 Parsed=action=(.*) where=(.*) form=(.*) color=(.*) localisation=(.*) Confidence=(.*) NP=(.*)", newVoiceCmd);
		bus.bindMsg("ICAR Gesture=(.*)",newDrawCmd);
	}
	catch (IvyException ie)
	{
	}
}


IvyMessageListener newVoiceCmd = new IvyMessageListener()
{
	public void receive(IvyClient client,String[] args)
	//Called at each new message from sra 
	{  
	if(Float.parseFloat(args[CONFIDENCE].replace(',','.')) <= confidenceThreshold)
		return;
		
	switch (mae) {
		case WAIT_FOR_ORDER:
			//Choose an action and start filling up an order
			switch (args[ACTION]) {
				case "CREATE":
					mae = FSM.DRAW;
					order = new OrderDraw(args[FORM],args[COLOR],args[LOCALISATION]);
					//order.debugPrint();
					break;
				case "MOVE":
					try {bus.sendMsg("ppilot5 Say='To move a shape, just click on it then click on where you want to put it, you can also ask by voice. A point will tell you which shape you selected. Say quitter if you want to stop moving shapes.'");} catch (Exception e) {	}
					formSelected = -1;
					mae=FSM.MOVE;
					break;
				case "DELETE":
					try {bus.sendMsg("ppilot5 Say='To delete a shape, just click on it or ask. If you want to quit, just say so.'");} catch (Exception e) {	}
					formSelected = -1;
					mae=FSM.DELETE;
					break;
				case "QUIT":
					bus.stop();
					bus = null;
					exit();
					break;
				default:
					break;
			}
			break;
		
		case DRAW:
			if (args[ACTION].equals("QUIT"))
				mae=FSM.WAIT_FOR_ORDER;
			if (args[ACTION].equals("CONFIRM")){
				formes.add(order.createForme());
				mae=FSM.WAIT_FOR_ORDER;
				break;
			}
			order.setColor(args[COLOR]);
			order.setPosition(args[LOCALISATION]);
			order.setForm(args[FORM]);
			order.debugPrint();
			break;
		
		case MOVE:
			if (args[ACTION].equals("QUIT"))
				mae=FSM.WAIT_FOR_ORDER;

			if(  args[WHERE].equals("THIS") )
				formSelected = getFormClicked();
			
			if( args[LOCALISATION].equals("THERE") ){
				if(formSelected != -1){
					formes.get(formSelected).setLocation(new Point(mouseX,mouseY));
					formSelected = -1;
				}
				else{
					try {bus.sendMsg("ppilot5 Say='You must first select a shape by clicking or asking.'");} catch (Exception e) {	}
				}
			}

			break;
		case DELETE:
			if (args[ACTION].equals("QUIT"))
				mae=FSM.WAIT_FOR_ORDER;
			if(  args[WHERE].equals("THIS") ){
				formSelected = getFormClicked();
				if(formSelected!=-1){
					formes.remove(formSelected);
					formSelected = -1;
				}
			}
			break;
		default :
			break;
		}
	}		
};

IvyMessageListener newDrawCmd = new IvyMessageListener()
{
	public void receive(IvyClient client,String[] args)
	//Called at each new message from ICAR
	{  
		switch(mae){
			case WAIT_FOR_ORDER:
				
				if(args[0].equals("YELLOW") || args[0].equals("GREEN") || args[0].equals("DARK") ||args[0].equals("BLUE") ||args[0].equals("RED") ||args[0].equals("ORANGE") ||args[0].equals("PURPLE")){
					order = new OrderDraw("undefined",args[0],"undefined");
					mae = mae.DRAW;
				}
				else if (!args[0].equals("CONFIRM")){
					order = new OrderDraw(args[0],"undefined","undefined");
					mae = mae.DRAW;
				}
				break;


			case DRAW:
				if(args[0].equals("CONFIRM")){
					formes.add(order.createForme());
					mae=FSM.WAIT_FOR_ORDER;
					break;
				} 
				if(args[0].equals("YELLOW") || args[0].equals("GREEN") || args[0].equals("DARK") ||args[0].equals("BLUE") ||args[0].equals("RED") ||args[0].equals("ORANGE") ||args[0].equals("PURPLE")){
					order.setColor(args[0]);
					break;
				}
				order.setForm(args[0]);
				break;

			case MOVE:		
				break;

			case DELETE:
				break;

			default :
				break;
		}
	}
};


public int getFormClicked()
{
	int foundForm =-1;
	Point m = new Point(mouseX, mouseY);
	for(int i=0; i<formes.size(); i++){
		if(formes.get(i).isClicked(m)){
			foundForm = i;
		}

	}
	return foundForm;
}


public void mousePressed()
{
	switch(mae){
		case WAIT_FOR_ORDER:
			if (formSelected == -1){
				formSelected = getFormClicked();
			}
			else{
				int newFormClicked = getFormClicked();
				if (newFormClicked == formSelected){
					formes.remove(formSelected);
					formSelected = -1;
					break;
				}
				else{
					formes.get(formSelected).setLocation(new Point(mouseX,mouseY));
					formSelected = -1;
				}

			}
			break;

		case DRAW:
			order.setPosition(new Point(mouseX,mouseY));
			break;
		case MOVE:
			if(formSelected == -1){
				formSelected = getFormClicked();		
			}
			else{
				formes.get(formSelected).setLocation(new Point(mouseX,mouseY));
				formSelected = -1;
		      	displayAll();
			}
			break;
		case DELETE:
			formSelected = getFormClicked();
			if(formSelected != -1){
				formes.remove(formSelected);
				formSelected = -1;
				displayAll();
			}
			break;
		default :
			break;
	}
}
/*
 * Classe Cercle
 */ 
 
public class Cercle extends Forme {
  
  int rayon;
  
  public Cercle(Point p) {
    super(p);
    this.rayon=80;
  }
   
  public void update() {
    fill(this.c);
    circle((int) this.origin.getX(),(int) this.origin.getY(),this.rayon);
  }  
   
  public boolean isClicked(Point p) {
    // vérifier que le cercle est cliqué
   PVector OM= new PVector( (int) (p.getX() - this.origin.getX()),(int) (p.getY() - this.origin.getY())); 
   if (OM.mag() <= this.rayon/2)
     return(true);
   else 
     return(false);
  }
  
  protected double perimetre() {
    return(2*PI*this.rayon);
  }
  
  protected double aire(){
    return(PI*this.rayon*this.rayon);
  }
}
public enum FSM {
  WAIT_FOR_ORDER, 
  DRAW,
  MOVE,
  DELETE
}
/*****
 * Création d'un nouvelle classe objet : Forme (Cercle, Rectangle, Triangle
 * 
 * Date dernière modification : 28/10/2019
 */

abstract class Forme {
 Point origin;
 int c;
 
 Forme(Point p) {
   this.origin=p;
   this.c = color(127);
 }
 
 public void setColor(int c) {
   this.c=c;
 }
 
 public int getColor(){
   return(this.c);
 }
 
 public abstract void update();
 
 public Point getLocation() {
   return(this.origin);
 }
 
 public void setLocation(Point p) {
   this.origin = p;
 }
 
 public abstract boolean isClicked(Point p);
 
 // Calcul de la distance entre 2 points
 protected double distance(Point A, Point B) {
    PVector AB = new PVector( (int) (B.getX() - A.getX()),(int) (B.getY() - A.getY())); 
    return(AB.mag());
 }
 
 protected abstract double perimetre();
 protected abstract double aire();
}
/*
 * Classe Losange
 */ 
 
public class Losange extends Forme {
  Point A, B,C,D;
  
  public Losange(Point p) {
    super(p);
    // placement des points
    A = new Point();    
    A.setLocation(p);
    B = new Point();    
    B.setLocation(A);
    C = new Point();  
    C.setLocation(A);
    D = new Point();
    D.setLocation(A);
    B.translate(40,60);
    D.translate(-40,60);
    C.translate(0,120);
  }
  
  public void setLocation(Point p) {
      super.setLocation(p);
      // redéfinition de l'emplacement des points
      A.setLocation(p);   
      B.setLocation(A);  
      C.setLocation(A);
      D.setLocation(A);
      B.translate(40,60);
      D.translate(-40,60);
      C.translate(0,120);   
  }
  
  public void update() {
    fill(this.c);
    quad((float) A.getX(), (float) A.getY(), (float) B.getX(), (float) B.getY(), (float) C.getX(), (float) C.getY(),  (float) D.getX(),  (float) D.getY());
  }  
  
  public boolean isClicked(Point M) {
    // vérifier que le losange est cliqué
    // aire du rectangle AMD + AMB + BMC + CMD = aire losange  
    if (round( (float) (aire_triangle(A,M,D) + aire_triangle(A,M,B) + aire_triangle(B,M,C) + aire_triangle(C,M,D))) == round((float) aire()))
      return(true);
    else 
      return(false);  
  }
  
  protected double perimetre() {
    //
    PVector AB= new PVector( (int) (B.getX() - A.getX()),(int) (B.getY() - A.getY())); 
    PVector BC= new PVector( (int) (C.getX() - B.getX()),(int) (C.getY() - B.getY())); 
    PVector CD= new PVector( (int) (D.getX() - C.getX()),(int) (D.getY() - C.getY())); 
    PVector DA= new PVector( (int) (A.getX() - D.getX()),(int) (A.getY() - D.getY())); 
    return( AB.mag()+BC.mag()+CD.mag()+DA.mag()); 
  }
  
  protected double aire(){
    PVector AC= new PVector( (int) (C.getX() - A.getX()),(int) (C.getY() - A.getY())); 
    PVector BD= new PVector( (int) (D.getX() - B.getX()),(int) (D.getY() - B.getY())); 
    return((AC.mag()*BD.mag())/2);
  } 
  
  private double perimetre_triangle(Point I, Point J, Point K) {
    //
    PVector IJ= new PVector( (int) (J.getX() - I.getX()),(int) (J.getY() - I.getY())); 
    PVector JK= new PVector( (int) (K.getX() - J.getX()),(int) (K.getY() - J.getY())); 
    PVector KI= new PVector( (int) (I.getX() - K.getX()),(int) (I.getY() - K.getY())); 
    
    return( IJ.mag()+JK.mag()+KI.mag()); 
  }
   
  // Calcul de l'aire d'un triangle par la méthode de Héron 
  private double aire_triangle(Point I, Point J, Point K){
    double s = perimetre_triangle(I,J,K)/2;
    double aire = s*(s-distance(I,J))*(s-distance(J,K))*(s-distance(K,I));
    return(sqrt((float) aire));
  }
}
public class OrderDraw{
    Point center;
    String shape;
    int c;

    public OrderDraw(String form, String colour, String loc){
        //Default values
        this.c = color(180, 180, 180);
        this.shape = "RECTANGLE";
        this.center = new Point(width/2,height/2);
        //Parameters values
        this.shape = form;
        this.setColor(colour);
        this.setPosition(loc);
    }

    public void debugPrint(){
        print("Shape :");
        //if(this.shape != null)
            print(this.shape);
        //else 
        //    print("undefined");
        
        print( "Center :");
        if(this.center != null)
            print(this.center.toString());
        else
            print("undefined");

        print(hex(this.c));
        println();
    }

    public void setColor(String newColor){
        if(!newColor.equals("undefined")){
            switch (newColor){
                case "RED":
                    this.c = color(255, 0, 0); break;
                case "ORANGE":
                    this.c = color(255, 150, 0); break;
                case "YELLOW":
                    this.c = color(255, 255, 0); break;
                case "GREEN":
                    this.c = color(0, 255, 0); break;
                case "BLUE":
                    this.c = color(0, 0, 255); break;
                case "PURPLE":
                    this.c = color(255, 0, 255); break;
                case "DARK":
                    this.c = color(10, 10, 10); break;
                default : 
                    this.c = color(180, 180, 180); break;
                
            }
        }
    }

    public void setPosition(String setupPos){
        if(!setupPos.equals("undefined")){
            this.center = new Point(mouseX,mouseY);
        }
    }
    public void setPosition(Point posPoint){
            this.center = posPoint;
    }

    public void setForm(String form){
        if(!form.equals("undefined")){
            this.shape = form;
        }
    }

    public Forme createForme(){
        Forme newForm;
        switch(this.shape){
            case "RECTANGLE":
                newForm = new Rectangle(this.center);
                newForm.setColor(this.c);
                break;
            case "TRIANGLE":
                newForm = new Triangle(this.center);
                newForm.setColor(this.c);
                break;
            case "CIRCLE":
                newForm = new Cercle(this.center);
                newForm.setColor(this.c);
                break;
            case "DIAMOND":
                newForm = new Losange(this.center);
                newForm.setColor(this.c);
                break;
            default:
                newForm = new Rectangle(this.center);
                newForm.setColor(this.c);
                break;

        }
        return newForm;
        
    }

    public void createPreview(){
        //Create a form and display it in the angle, the form is not saved
        Forme newForm;
        Point previewPoint = new Point(width - 100,height - 200);
        switch(this.shape){
            case "RECTANGLE":
                newForm = new Rectangle(previewPoint);
                newForm.setColor(this.c);
                break;
            case "TRIANGLE":
                newForm = new Triangle(previewPoint);
                newForm.setColor(this.c);
                break;
            case "CIRCLE":
                newForm = new Cercle(previewPoint);
                newForm.setColor(this.c);
                break;
            case "DIAMOND":
                newForm = new Losange(previewPoint);
                newForm.setColor(this.c);
                break;
            default:
                newForm = new Rectangle(previewPoint);
                newForm.setColor(this.c);
                break;
        }
        newForm.update();
        circle((float)this.center.getX(), (float)this.center.getY(), 10.f);

    }
}
/*
 * Classe Rectangle
 */ 
 
public class Rectangle extends Forme {
  
  int longueur;
  
  public Rectangle(Point p) {
    super(p);
    this.longueur=60;
  }
   
  public void update() {
    fill(this.c);
    square((int) this.origin.getX(),(int) this.origin.getY(),this.longueur);
  }  
  
  public boolean isClicked(Point p) {
    int x= (int) p.getX();
    int y= (int) p.getY();
    int x0 = (int) this.origin.getX();
    int y0 = (int) this.origin.getY();
    
    // vérifier que le rectangle est cliqué
    if ((x>x0) && (x<x0+this.longueur) && (y>y0) && (y<y0+this.longueur))
      return(true);
    else  
      return(false);
  }
  
  // Calcul du périmètre du carré
  protected double perimetre() {
    return(this.longueur*4);
  }
  
  protected double aire(){
    return(this.longueur*this.longueur);
  }
}
/*
 * Classe Triangle
 */ 
 
public class Triangle extends Forme {
  Point A, B,C;
  public Triangle(Point p) {
    super(p);
    // placement des points
    A = new Point();    
    A.setLocation(p);
    B = new Point();    
    B.setLocation(A);
    C = new Point();    
    C.setLocation(A);
    B.translate(40,60);
    C.translate(-40,60);
  }
  
    public void setLocation(Point p) {
      super.setLocation(p);
      // redéfinition de l'emplacement des points
      A.setLocation(p);   
      B.setLocation(A);  
      C.setLocation(A);
      B.translate(40,60);
      C.translate(-40,60);   
  }
  
  public void update() {
    fill(this.c);
    triangle((float) A.getX(), (float) A.getY(), (float) B.getX(), (float) B.getY(), (float) C.getX(), (float) C.getY());
  }  
  
  public boolean isClicked(Point M) {
    // vérifier que le triangle est cliqué
    
    PVector AB= new PVector( (int) (B.getX() - A.getX()),(int) (B.getY() - A.getY())); 
    PVector AC= new PVector( (int) (C.getX() - A.getX()),(int) (C.getY() - A.getY())); 
    PVector AM= new PVector( (int) (M.getX() - A.getX()),(int) (M.getY() - A.getY())); 
    
    PVector BA= new PVector( (int) (A.getX() - B.getX()),(int) (A.getY() - B.getY())); 
    PVector BC= new PVector( (int) (C.getX() - B.getX()),(int) (C.getY() - B.getY())); 
    PVector BM= new PVector( (int) (M.getX() - B.getX()),(int) (M.getY() - B.getY())); 
    
    PVector CA= new PVector( (int) (A.getX() - C.getX()),(int) (A.getY() - C.getY())); 
    PVector CB= new PVector( (int) (B.getX() - C.getX()),(int) (B.getY() - C.getY())); 
    PVector CM= new PVector( (int) (M.getX() - C.getX()),(int) (M.getY() - C.getY())); 
    
    if ( ((AB.cross(AM)).dot(AM.cross(AC)) >=0) && ((BA.cross(BM)).dot(BM.cross(BC)) >=0) && ((CA.cross(CM)).dot(CM.cross(CB)) >=0) ) { 
      return(true);
    }
    else
      return(false);
  }
  
  protected double perimetre() {
    //
    PVector AB= new PVector( (int) (B.getX() - A.getX()),(int) (B.getY() - A.getY())); 
    PVector AC= new PVector( (int) (C.getX() - A.getX()),(int) (C.getY() - A.getY())); 
    PVector BC= new PVector( (int) (C.getX() - B.getX()),(int) (C.getY() - B.getY())); 
    
    return( AB.mag()+AC.mag()+BC.mag()); 
  }
   
  // Calcul de l'aire du triangle par la méthode de Héron 
  protected double aire(){
    double s = perimetre()/2;
    double aire = s*(s-distance(B,C))*(s-distance(A,C))*(s-distance(A,B));
    return(sqrt((float) aire));
  }
}
  public void settings() { 	size(800,800); }
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "putThatThere" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
