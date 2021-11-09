public class OrderDraw extends Order{
    Point center;
    String shape;
    color c;

    //SRA decryption key 
    private int ACTION			= 0;
    private int WHERE			= 1;
    private int FORM			= 2;
    private int COLOR			= 3;
    private int LOCALISATION	= 4;
    private int CONFIDENCE		= 5;

    public OrderDraw(String[] argsFromSra){
        this.shape = argsFromSra[FORM]);
        switch (argsFromSra[COLOR]){
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
