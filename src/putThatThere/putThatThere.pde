import fr.dgac.ivy.*;
import java.awt.Point;
// data
ArrayList<Forme> formes;
Ivy bus;
OrderDraw order;
float confidenceThreshold =  0.6;
FSM mae;
//SRA decryption key 
private int ACTION			= 0;
private int WHERE			= 1;
private int FORM			= 2;
private int COLOR			= 3;
private int LOCALISATION	= 4;
private int CONFIDENCE		= 5;

int formSelected = -1;

void setup()
{
	size(800,800);
	surface.setResizable(true);
	background(255);
	formes = new ArrayList<Forme>();
	mae = FSM.WAIT_FOR_ORDER;
	setupIvy();
}

void draw()
{
	switch (mae) {
		case WAIT_FOR_ORDER:
			displayAll();
			break;
		case DRAW:
			displayAll();
			if(order != null){
				order.createPreview();
			}
			break;
		case MOVE:
			mae=FSM.WAIT_FOR_ORDER;
			break;
		case DELETE:
			mae=FSM.WAIT_FOR_ORDER;
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
					mae=FSM.MOVE;
					break;
				case "DELETE":
					mae=FSM.DELETE;
					break;
				case "QUIT":
					exit();
					break;
				default:
					break;
			}
			break;
		
		case DRAW:
			if (args[ACTION].equals("QUIT"))
				exit();
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
			break;
		case DELETE:
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
					//on fait un mouvement
					//TODO mae MOVE
				}

			}
			break;

		case DRAW:
			order.setPosition(new Point(mouseX,mouseY));
			break;
		case MOVE:
			break;
		case DELETE:
			break;
		default :
			break;
	}
}
