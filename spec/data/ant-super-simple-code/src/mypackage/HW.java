package mypackage;

import org.apache.log4j.Logger;
import org.apache.log4j.BasicConfigurator;

public class HW
{
    static Logger logger = Logger.getLogger(HW.class);
    public static void main(String [] args)
    {
        BasicConfigurator.configure();
        logger.info("Hello World");
    }

}
