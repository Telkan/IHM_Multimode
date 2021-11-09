import fr.dgac.ivy.*;
import java.awt.Point;
// data
ArrayList<Forme> formes;
Ivy bus;
Order order;

FSM mae;



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
			break;
		case MOVE:
			break;
		case DELETE:
			break;
		default :
			mae = FSM.WAIT_FOR_ORDER;	
			break;
	}
}

void mousePressed()
{
	
}


void displayAll(){
	background(255);
	for(Forme current: formes)
		current.update();
}

void setupIvy(){
	//Setup Ivy and all the listeners 
	try
	{
		bus = new Ivy("multimod", " Ready to draw some things!", null);
		bus.start("127.255.255.255:2010");
		bus.bindMsg("^sra5 Parsed=action=(.*) where=(.*) form=(.*) color=(.*) localisation=(.*) Confidence=(.*) ", newMsgFromSra);
	
	}
	catch (IvyException ie)
	{
	}
}





IvyMessageListener newMsgFromSra =	new IvyMessageListener()
{
	public void receive(IvyClient client,String[] args)
	//Called at each new message from sra 
	{
		switch (mae) {
		case WAIT_FOR_ORDER:
			//Choose an action and start filling up an order
			switch (args[ACTION]) {
				case "CREATE":
					mae = FSM.DRAW;
					order = new OrderDraw(args);

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
