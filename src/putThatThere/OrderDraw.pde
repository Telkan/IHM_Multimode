public class OrderDraw{
    Point center;
    String shape;
    color c;

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
        circle((float)this.center.getX(), (float)this.center.getY(), 10.);

    }
}
