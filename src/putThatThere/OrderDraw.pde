public class OrderDraw{
    Point center;
    String shape;
    color c;

    public OrderDraw(String form, String colour, String loc){
        this.shape = form;
        this.setColor(colour);
        this.setPosition(loc);
    }

    public void debugPrint(){
        print("Shape :");
        if(this.shape != null)
            print(this.shape);
        else 
            print("undefined");
        
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

    public void setForm(String form){
        if(!form.equals("undefined")){
            this.shape = form;
        }
    }

    public Forme createForme(){
        Forme newForm;
        switch(this.shape){
            case "RECTANGLE":
            default:
                newForm = new Rectangle(this.center);
                newForm.setColor(this.c);
                break;
        }
        return newForm;
    }

    public void createPreview(){

    }
}
