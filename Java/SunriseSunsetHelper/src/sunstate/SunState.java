package sunstate;

import java.io.BufferedReader;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.zip.GZIPInputStream;

import org.json.JSONObject;
import org.json.JSONString;

public class SunState {

	public static void main(String[] args) {
		String url = "http://api.sunrise-sunset.org/json";
		url = "https://weather.cit.api.here.com/weather/1.0/report.json?product=forecast_astronomy&name=New%20York&app_id=DemoAppId01082013GAL&app_code=AJKnXv84fjrb0KIHawS0Tg";
		url = "http://api.sunrise-sunset.org/json?lat=48.294016&lng=14.304057&formatted=0";
		try{
		URL obj = new URL(url);
		HttpURLConnection con = (HttpURLConnection) obj.openConnection();

		// optional default is GET
		con.setRequestMethod("GET");
		con.setDoOutput(true);

		//add request header
		//con.setRequestProperty("lat", "48.294016");
		//con.setRequestProperty("lng", "14.304057");
		//con.setRequestProperty("date", "today");
		
		//48.294016, 14.304057
		con.connect();
		
		int responseCode = con.getResponseCode();
		
		System.out.println("\nSending 'GET' request to URL : " + url);
		System.out.println("Response Code : " + responseCode);
		System.out.println("Message: " + con.getResponseMessage());
		System.out.println(con.getContentType() + con.getContentEncoding()+ con.getContentLength());
		//System.out.println(con.);
		
		InputStream is = con.getInputStream();
		InputStreamReader isr = new InputStreamReader((is));
		
		
		BufferedReader in = new BufferedReader(isr);
	
		String resultString = in.readLine();

		
		in.close();

		//print result
		System.out.println(resultString);
		
		JSONObject json = new JSONObject(resultString);
		System.out.println(json.getJSONObject("results").getString("sunrise"));
		}
		catch(Exception e)
		{
			e.printStackTrace();
		}

	}
	
	public String getSunrise(String date, double lat, double lng)
	{
		
		
		return "";
	}
	
	

}
