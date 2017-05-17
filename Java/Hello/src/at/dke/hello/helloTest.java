package at.dke.hello;

import jollyday.JollydayHelper;
import de.jollyday.HolidayManager;

public class helloTest {
	private String test = "world";
	
	public helloTest(String test)
	{
		this.test = test;
	}
	public helloTest()
	{
		this.test = "helllo";
	}
	public static void main(String[] args)
	{
		JollydayHelper.isHoliday("", "at");
		
	}
	
	public String getText()
	{
		return this.test;
	}

}
