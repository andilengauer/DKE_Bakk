package jollyday;

import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.Date;
import java.util.Iterator;
import java.util.Set;

import de.jollyday.Holiday;
import de.jollyday.HolidayManager;


public class JollydayHelper {
	
	public static void main(String[] args) {
JollydayHelper.getHolidays(null, null, "at");
		
		Calendar c = Calendar.getInstance();
		c.set(2017, 0, 1);
		System.out.println(JollydayHelper.isHoliday("2017-01-01", "ny"));
	}
	
	
	public static void getHolidays(Date from , Date to, String country)
	{
		Set<Holiday> holidays = HolidayManager.getInstance().getHolidays(2017, "at");
		Iterator<Holiday> i = holidays.iterator();
		while(i.hasNext())
		{
			Holiday h = i.next();
			System.out.println(h.getDescription() + h.getDate().toString());
			
		}
			
	}
	public static Boolean isHoliday(String date, String country)
	{
		SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");
		Date input = new Date();
		try {
			input = sdf.parse(date);
		} catch (ParseException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		Calendar cal = Calendar.getInstance();
		cal.setTime(input);
		//HolidayManager.getInstance(HolidayCalendar.AUSTRIA).isHoliday(c, HolidayType., args)
		//HolidayCalendar.AUSTRIA
		return HolidayManager.getInstance().isHoliday(cal,country);
	}
	
		
	public static Boolean isTest(int y, int m, int d)
	{
		Calendar c = Calendar.getInstance();
		return y == 2017;
	}
}
