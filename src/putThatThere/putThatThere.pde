import fr.dgac.ivy.*;
import java.awt.Point;
// data
ArrayList<Forme> formes;
Ivy bus;
OrderDraw order;
float confidenceThreshold =  0.7;
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

void setup()
{
	size(800,800);
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

void draw()
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
				circle((float)posSelected.getX(), (float)posSelected.getY(), 10.);
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




void displayAll(){
	background(255);
	int i = 0;
	while(i < formes.size()){
		formes.get(i).update();
		i++;
	}

}

void setupIvy(){
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


int getFormClicked()
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


void mousePressed()
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
