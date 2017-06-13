package sunstate;

import java.io.BufferedReader;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
import org.json.JSONObject;

public class SunState {
	
	private static String URL ="http://api.sunrise-sunset.org/json?";

	public static void main(String[] args) {
		String sunrise = getSunrise("2017-06-13","37.7213","-122.2207");
		String sunset = getSunset("2017-06-13","37.7213","-122.2207");
		
		System.out.println("Sunrise: " + sunrise + "\r\nSunset: " + sunset);

	}
	
	public static String getSunrise(String date, String lat, String lng)
	{
		
		
		JSONObject result = getSunState(date,lat,lng);
		
		try{
			return result.getString("sunrise");
		}
		catch(Exception e)
		{
			return "";
		}
	}
	
	public static String getSunset(String date, String lat, String lng)
	{
		
		
		JSONObject result = getSunState(date,lat,lng);
		
		try{
			return result.getString("sunset");
		}
		catch(Exception e)
		{
			return "";
		}
	}

	private static JSONObject getSunState(String date, String lat, String lng) {
		String requestUrl = URL + "lat=" + lat + "&lng="+lng+"&date"+date+ "&formatted=0";
		
		try{
			URL obj = new URL(requestUrl);
			HttpURLConnection con = (HttpURLConnection) obj.openConnection();

			// optional default is GET
			con.setRequestMethod("GET");
			con.setDoOutput(true);

			//48.294016, 14.304057
			//con.connect();
			
			int responseCode = con.getResponseCode();
			
			System.out.println("\nSending 'GET' request to URL : " + requestUrl);
			System.out.println("Response Code : " + responseCode);
			System.out.println("Message: " + con.getResponseMessage());
			
			InputStream is = con.getInputStream();
			InputStreamReader isr = new InputStreamReader((is));
			
			
			BufferedReader in = new BufferedReader(isr);
		
			String resultString = in.readLine();

			
			in.close();

			//print result
			System.out.println(resultString);
			
			JSONObject jsonResponse = new JSONObject(resultString);
			
			return jsonResponse.getJSONObject("results");
			}
			catch(Exception e)
			{
				e.printStackTrace();
				return null;
			}
		
	}
	
	

}
