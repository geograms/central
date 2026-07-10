// list of items that we should show
var matches = [
 {
  type: "source",
  files: [
	 {
	   filename: "./adblockplusandroid-2014-06-01/jni/v8/v8.h (BSD-3-Clause, MIT)",
	   matches_bin: [
	 		  ["TLSH","98","bitbucket:android_vendor_qcom_opensource_v8\/include\/v8.h"],
	 		  ["TLSH","94","<a href=\"https:\/\/code.google.com\/archive\/p\/webapptools\/source\/default\/source\" target=\"_blank\">googlecode:webapptools\/sourcecode\/webapptools-read-only\/ext_tools\/include\/v8\/v8.h<\/a>"],
	 		  ["TLSH","87","bitbucket:node\/deps\/v8\/include\/v8.h"],
	 		  ["TLSH","77","<a href=\"https:\/\/code.google.com\/archive\/p\/js-cgi\/source\/default\/source\" target=\"_blank\">googlecode:js-cgi\/sourcecode\/js-cgi-read-only\/include\/v8.h<\/a>"]
	 		 ]
	 },
	 {
	   filename: "./adblockplusandroid-2014-06-01/jni/v8/v8stdint.h (BSD-3-Clause)",
	   matches_bin: [
	 		  ["SHA1","100","<a href=\"http:\/\/sourceforge.net\/projects\/bonkenc\" target=\"_blank\">sourceforge:bonkenc\/downloads\/snapshots\/20131217\/freac-cdk-201312..dows-x64.zip::freac-cdk-20131217-x64\/include\/smooth-js\/v8stdint.h<\/a>"],
	 		  ["SHA1","100","<a href=\"https:\/\/code.google.com\/archive\/p\/himctop\/source\/default\/source\" target=\"_blank\">googlecode:himctop\/sourcecode\/himctop-read-only\/node-v0.8.12\/deps\/v8\/include\/v8stdint.h<\/a>"],
	 		  ["SHA1","100","<a href=\"https:\/\/github.com\/flowerman\/boards\/blob\/master\/vendor\/bundle\/ruby\/2.1.0\/gems\/libv8-3.16.14.7-x86_64-linux\/vendor\/v8\/include\/v8stdint.h\" target=\"_blank\">github:flowerman\/boards.zip::flowerman-boards-b5add20\/vendor\/bund...0\/gems\/libv8-3.16.14.7-x86_64-linux\/vendor\/v8\/include\/v8stdint.h<\/a>"]
	 		 ]
	 },
	 {
	   filename: "./adblockplusandroid-2014-06-01/src/org/adblockplus/android/AboutDialog.java (GPL-3.0)",
	   matches_bin: [
	 		  ["SHA1","100","<a href=\"https:\/\/github.com\/pombredanne\/tokenizator\/blob\/master\/run\/sample\/java\/AboutDialog.java\" target=\"_blank\">github:pombredanne\/tokenizator.zip::pombredanne-tokenizator-1a68652\/run\/sample\/java\/AboutDialog.java<\/a>"]
	 		 ]
	 },
	 {
	   filename: "./adblockplusandroid-2014-06-01/src/org/adblockplus/android/ABPEngine.java (GPL-3.0)",
	   matches_bin: [
	 		  ["SHA1","100","<a href=\"https:\/\/github.com\/pombredanne\/tokenizator\/blob\/master\/run\/sample\/java\/ABPEngine.java\" target=\"_blank\">github:pombredanne\/tokenizator.zip::pombredanne-tokenizator-1a68652\/run\/sample\/java\/ABPEngine.java<\/a>"]
	 		 ]
	 },
	 {
	   filename: "./adblockplusandroid-2014-06-01/src/org/adblockplus/android/AdblockPlus.java (GPL-3.0)",
	   matches_bin: [
	 		  ["SHA1","100","<a href=\"https:\/\/github.com\/pombredanne\/tokenizator\/blob\/master\/run\/sample\/java\/AdblockPlus.java\" target=\"_blank\">github:pombredanne\/tokenizator.zip::pombredanne-tokenizator-1a68652\/run\/sample\/java\/AdblockPlus.java<\/a>"]
	 		 ],
	   matches_source: [  
	 	{ 
	 	  lines: "97..111",
	 	  code: "  private static class ReferrerMappingCache extends LinkedHashMap&#60;String, String&#62;\n  {\n    private static final long serialVersionUID = 1L;\n    private static final int MAX_SIZE = 5000;\n\n    public ReferrerMappingCache()\n    {\n      super(MAX_SIZE + 1, 0.75f, true);\n    }\n\n    @Override\n    protected boolean removeEldestEntry(final Map.Entry&#60;String, String&#62; eldest)\n    {\n      return size() &#62; MAX_SIZE;\n    }\n  };\n",
	 	  similarity: [
	 		{
	 		  percent: 98,
	 		  lines: "97..111",
	 		  reference: "<a href=\"https:\/\/github.com\/pombredanne\/tokenizator\/blob\/master\/run\/sample\/java\/AdblockPlus.java#L97-L111\" target=\"_blank\">github-2016:pombredanne\/tokenizator.zip::pombredanne-tokenizator-1a68652\/run\/sample\/java\/AdblockPlus.java>>>97:111<\/a>"
	 		}
	 	  ]
	 	},
	 	{ 
	 	  lines: "124..137",
	 	  code: "  public int getBuildNumber()\n  {\n    int buildNumber = -1;\n    try\n    {\n      final PackageInfo pi = getPackageManager().getPackageInfo(getPackageName(), 0);\n      buildNumber = pi.versionCode;\n    }\n    catch (final NameNotFoundException e)\n    {\n      \/\/ ignore - this shouldn\"t happen\n      Log.e(TAG, e.getMessage(), e);\n    }\n    return buildNumber;\n  }\n",
	 	  similarity: [
	 		{
	 		  percent: 98,
	 		  lines: "124..137",
	 		  reference: "<a href=\"https:\/\/github.com\/pombredanne\/tokenizator\/blob\/master\/run\/sample\/java\/AdblockPlus.java#L124-L137\" target=\"_blank\">github-2016:pombredanne\/tokenizator.zip::pombredanne-tokenizator-1a68652\/run\/sample\/java\/AdblockPlus.java>>>124:137<\/a>"
	 		}
	 	  ]
	 	},
	 	{ 
	 	  lines: "143..163",
	 	  code: "  public static void showAppDetails(final Context context)\n  {\n    final String packageName = context.getPackageName();\n    final Intent intent = new Intent();\n    if (Build.VERSION.SDK_INT &#62;= Build.VERSION_CODES.GINGERBREAD)\n    {\n      \/\/ above 2.3\n      intent.setAction(Settings.ACTION_APPLICATION_DETAILS_SETTINGS);\n      final Uri uri = Uri.fromParts(\"package\", packageName, null);\n      intent.setData(uri);\n    }\n    else\n    {\n      \/\/ below 2.3\n      final String appPkgName = (Build.VERSION.SDK_INT == Build.VERSION_CODES.FROYO ? \"pkg\" : \"com.android.settings.ApplicationPkgName\");\n      intent.setAction(Intent.ACTION_VIEW);\n      intent.setClassName(\"com.android.settings\", \"com.android.settings.InstalledAppDetails\");\n      intent.putExtra(appPkgName, packageName);\n    }\n    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);\n    context.startActivity(intent);\n  }\n",
	 	  similarity: [
	 		{
	 		  percent: 99,
	 		  lines: "143..163",
	 		  reference: "<a href=\"https:\/\/github.com\/pombredanne\/tokenizator\/blob\/master\/run\/sample\/java\/AdblockPlus.java#L143-L163\" target=\"_blank\">github-2016:pombredanne\/tokenizator.zip::pombredanne-tokenizator-1a68652\/run\/sample\/java\/AdblockPlus.java>>>143:163<\/a>"
	 		}
	 	  ]
	 	},
	 	{ 
	 	  lines: "179..195",
	 	  code: "  public static void appendRawTextFile(final Context context, final StringBuilder text, final int id)\n  {\n    \/\/ TODO: What about closing the resources?\n    final InputStream inputStream = context.getResources().openRawResource(id);\n    final InputStreamReader in = new InputStreamReader(inputStream);\n    final BufferedReader buf = new BufferedReader(in);\n    String line;\n    try\n    {\n      while ((line = buf.readLine()) != null)\n        text.append(line);\n    }\n    catch (final IOException e)\n    {\n      \/\/ TODO: How about real logging?\n      e.printStackTrace();\n    }\n  }\n",
	 	  similarity: [
	 		{
	 		  percent: 99,
	 		  lines: "179..195",
	 		  reference: "<a href=\"https:\/\/github.com\/pombredanne\/tokenizator\/blob\/master\/run\/sample\/java\/AdblockPlus.java#L179-L195\" target=\"_blank\">github-2016:pombredanne\/tokenizator.zip::pombredanne-tokenizator-1a68652\/run\/sample\/java\/AdblockPlus.java>>>179:195<\/a>"
	 		}
	 	  ]
	 	},
	 	{ 
	 	  lines: "201..209",
	 	  code: "  public static boolean isWiFiConnected(final Context context)\n  {\n    final ConnectivityManager connectivityManager = (ConnectivityManager) context.getSystemService(Context.CONNECTIVITY_SERVICE);\n    NetworkInfo networkInfo = null;\n    if (connectivityManager != null)\n    {\n      networkInfo = connectivityManager.getNetworkInfo(ConnectivityManager.TYPE_WIFI);\n    }\n    return networkInfo == null ? false : networkInfo.isConnected();\n  }\n",
	 	  similarity: [
	 		{
	 		  percent: 95,
	 		  lines: "102..111",
	 		  reference: "<a href=\"https:\/\/code.google.com\/archive\/p\/wireless-barcode-scanner\/source\/default\/source\" target=\"_blank\">googlecode:wireless-barcode-scanner\/sourcecode\/wireless-barcode-s..de\/zwiebelchen\/wirelessbarcodescanner\/MenuActivity.java>>>102:111<\/a>"
	 		},
	 		{
	 		  percent: 95,
	 		  lines: "8..15",
	 		  reference: "<a href=\"https:\/\/code.google.com\/archive\/p\/maxbusko\/source\/default\/source\" target=\"_blank\">googlecode:maxbusko\/sourcecode\/maxbusko-read-only\/formula\/v3.0\/src\/max\/busko\/formula\/calendar\/utils\/NetworkUtils.java>>>8:15<\/a>"
	 		},
	 		{
	 		  percent: 95,
	 		  lines: "8..15",
	 		  reference: "<a href=\"https:\/\/code.google.com\/archive\/p\/maxbusko\/source\/default\/source\" target=\"_blank\">googlecode:maxbusko\/sourcecode\/maxbusko-read-only\/formula\/v3.2.1\/src\/max\/busko\/formula\/calendar\/utils\/NetworkUtils.java>>>8:15<\/a>"
	 		},
	 		{
	 		  percent: 95,
	 		  lines: "8..15",
	 		  reference: "<a href=\"https:\/\/code.google.com\/archive\/p\/maxbusko\/source\/default\/source\" target=\"_blank\">googlecode:maxbusko\/sourcecode\/maxbusko-read-only\/formula\/v3.3.1\/src\/max\/busko\/formula\/calendar\/utils\/NetworkUtils.java>>>8:15<\/a>"
	 		},
	 		{
	 		  percent: 95,
	 		  lines: "8..15",
	 		  reference: "<a href=\"https:\/\/code.google.com\/archive\/p\/maxbusko\/source\/default\/source\" target=\"_blank\">googlecode:maxbusko\/sourcecode\/maxbusko-read-only\/formula\/v3.1.1\/src\/max\/busko\/formula\/calendar\/utils\/NetworkUtils.java>>>8:15<\/a>"
	 		}
	 	  ]
	 	},
	 	{ 
	 	  lines: "217..226",
	 	  code: "  public boolean isServiceRunning()\n  {\n    final ActivityManager manager = (ActivityManager) getSystemService(ACTIVITY_SERVICE);\n    \/\/ Actually it returns not only running services, so extra check is required\n    for (final RunningServiceInfo service : manager.getRunningServices(Integer.MAX_VALUE))\n    {\n      if (service.service.getClassName().equals(ProxyService.class.getCanonicalName()) && service.pid &#62; 0)\n        return true;\n    }\n    return false;\n  }\n",
	 	  similarity: [
	 		{
	 		  percent: 85,
	 		  lines: "102..110",
	 		  reference: "<a href=\"http:\/\/stackoverflow.com\/a\/17402116\" target=\"_blank\">http:\/\/stackoverflow.com\/a\/17402116<\/a>"
	 		},
	 		{
	 		  percent: 85,
	 		  lines: "346..354",
	 		  reference: "<a href=\"http:\/\/stackoverflow.com\/a\/19058177\" target=\"_blank\">http:\/\/stackoverflow.com\/a\/19058177<\/a>"
	 		},
	 		{
	 		  percent: 85,
	 		  lines: "43..51",
	 		  reference: "<a href=\"http:\/\/stackoverflow.com\/a\/24210110\" target=\"_blank\">http:\/\/stackoverflow.com\/a\/24210110<\/a>"
	 		},
	 		{
	 		  percent: 82,
	 		  lines: "292..300",
	 		  reference: "<a href=\"http:\/\/sourceforge.net\/projects\/agpframework\" target=\"_blank\">sourceforge:agpframework\/downloads\/AGP-framework-0.6\/AGP-framewor..\/ict\/qcat\/GPFramework\/Interpretor\/InterpretorShell.java>>>292:300<\/a>"
	 		},
	 		{
	 		  percent: 82,
	 		  lines: "275..283",
	 		  reference: "<a href=\"http:\/\/sourceforge.net\/projects\/agpframework\" target=\"_blank\">sourceforge:agpframework\/downloads\/AGP-framework-0.5\/AGP-framewor..\/ict\/qcat\/GPFramework\/Interpretor\/InterpretorShell.java>>>275:283<\/a>"
	 		}
	 	  ]
	 	},
	 	{ 
	 	  lines: "370..545",
	 	  code: "    if (accept != null)\n    {\n      if (accept.contains(\"text\/css\"))\n        contentType = \"STYLESHEET\";\n      else if (accept.contains(\"image\/*\"))\n        contentType = \"IMAGE\";\n      else if (accept.contains(\"text\/html\"))\n        contentType = \"SUBDOCUMENT\";\n    }\n\n    if (contentType == null)\n    {\n      if (RE_JS.matcher(url).matches())\n        contentType = \"SCRIPT\";\n      else if (RE_CSS.matcher(url).matches())\n        contentType = \"STYLESHEET\";\n      else if (RE_IMAGE.matcher(url).matches())\n        contentType = \"IMAGE\";\n      else if (RE_FONT.matcher(url).matches())\n        contentType = \"FONT\";\n      else if (RE_HTML.matcher(url).matches())\n        contentType = \"SUBDOCUMENT\";\n    }\n    if (contentType == null)\n      contentType = \"OTHER\";\n\n    final List&#60;String&#62; referrerChain = buildReferrerChain(referrer);\n    Log.d(\"Referrer chain\", fullUrl + \": \" + referrerChain.toString());\n    final String[] referrerChainArray = referrerChain.toArray(new String[referrerChain.size()]);\n    return abpEngine.matches(fullUrl, contentType, referrerChainArray);\n  }\n\n  private List&#60;String&#62; buildReferrerChain(String url)\n  {\n    final List&#60;String&#62; referrerChain = new ArrayList&#60;String&#62;();\n    \/\/ We need to limit the chain length to ensure we don\"t block indefinitely if there\"s\n    \/\/ a referrer loop.\n    final int maxChainLength = 10;\n    for (int i = 0; i &#60; maxChainLength && url != null; i++)\n    {\n      referrerChain.add(0, url);\n      url = referrerMapping.get(url);\n    }\n    return referrerChain;\n  }\n\n  \/**\n   * Checks if filtering is enabled.\n   *\/\n  public boolean isFilteringEnabled()\n  {\n    return filteringEnabled;\n  }\n\n  \/**\n   * Enables or disables filtering.\n   *\/\n  public void setFilteringEnabled(final boolean enable)\n  {\n    filteringEnabled = enable;\n    sendBroadcast(new Intent(BROADCAST_FILTERING_CHANGE).putExtra(\"enabled\", filteringEnabled));\n  }\n\n  \/**\n   * Starts ABP engine. It also initiates subscription refresh if it is enabled\n   * in user settings.\n   *\/\n  public void startEngine()\n  {\n    if (abpEngine == null)\n    {\n      final File basePath = getFilesDir();\n      abpEngine = ABPEngine.create(AdblockPlus.getApplication(), ABPEngine.generateAppInfo(this), basePath.getAbsolutePath());\n    }\n  }\n\n  \/**\n   * Stops ABP engine.\n   *\/\n  public void stopEngine()\n  {\n    if (abpEngine != null)\n    {\n      abpEngine.dispose();\n      abpEngine = null;\n      Log.i(TAG, \"stopEngine\");\n    }\n  }\n\n  \/**\n   * Initiates immediate interactive check for available update.\n   *\/\n  public void checkUpdates()\n  {\n    abpEngine.checkForUpdates();\n  }\n\n  \/**\n   * Sets Alarm to call updater after specified number of minutes or after one\n   * day if\n   * minutes are set to 0.\n   *\n   * @param minutes\n   *          number of minutes to wait\n   *\/\n  public void scheduleUpdater(final int minutes)\n  {\n    final Calendar updateTime = Calendar.getInstance();\n\n    if (minutes == 0)\n    {\n      \/\/ Start update checks at 10:00 GMT...\n      updateTime.setTimeZone(TimeZone.getTimeZone(\"GMT\"));\n      updateTime.set(Calendar.HOUR_OF_DAY, 10);\n      updateTime.set(Calendar.MINUTE, 0);\n      \/\/ ...next day\n      updateTime.add(Calendar.HOUR_OF_DAY, 24);\n      \/\/ Spread out the \u201Cmass downloading\u201D for 6 hours\n      updateTime.add(Calendar.MINUTE, (int) (Math.random() * 60 * 6));\n    }\n    else\n    {\n      updateTime.add(Calendar.MINUTE, minutes);\n    }\n\n    final Intent updater = new Intent(this, AlarmReceiver.class);\n    final PendingIntent recurringUpdate = PendingIntent.getBroadcast(this, 0, updater, PendingIntent.FLAG_CANCEL_CURRENT);\n    \/\/ Set non-waking alarm\n    final AlarmManager alarms = (AlarmManager) getSystemService(Context.ALARM_SERVICE);\n    alarms.set(AlarmManager.RTC, updateTime.getTimeInMillis(), recurringUpdate);\n  }\n\n  @Override\n  public void onCreate()\n  {\n    super.onCreate();\n    instance = this;\n\n    \/\/ Check for crash report\n    try\n    {\n      final InputStreamReader reportFile = new InputStreamReader(openFileInput(CrashHandler.REPORT_FILE));\n      final char[] buffer = new char[0x1000];\n      final StringBuilder out = new StringBuilder();\n      int read;\n      do\n      {\n        read = reportFile.read(buffer, 0, buffer.length);\n        if (read &#62; 0)\n          out.append(buffer, 0, read);\n      }\n      while (read &#62;= 0);\n      final String report = out.toString();\n      if (StringUtils.isNotEmpty(report))\n      {\n        final Intent intent = new Intent(this, CrashReportDialog.class);\n        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);\n        intent.putExtra(\"report\", report);\n        startActivity(intent);\n      }\n    }\n    catch (final FileNotFoundException e)\n    {\n      \/\/ ignore\n    }\n    catch (final IOException e)\n    {\n      Log.e(TAG, e.getMessage(), e);\n    }\n\n    \/\/ Set crash handler\n    Thread.setDefaultUncaughtExceptionHandler(new CrashHandler(this));\n\n    \/\/ Initiate update check\n    scheduleUpdater(0);\n  }\n}\n",
	 	  similarity: [
	 		{
	 		  percent: 99,
	 		  lines: "370..545",
	 		  reference: "<a href=\"https:\/\/github.com\/pombredanne\/tokenizator\/blob\/master\/run\/sample\/java\/AdblockPlus.java#L370-L545\" target=\"_blank\">github-2016:pombredanne\/tokenizator.zip::pombredanne-tokenizator-1a68652\/run\/sample\/java\/AdblockPlus.java>>>370:545<\/a>"
	 		}
	 	  ]
	 	}
	   ]
	 },
	 {
	   filename: "./adblockplusandroid-2014-06-01/src/org/adblockplus/android/AdvancedPreferences.java (GPL-3.0)",
	   matches_bin: [
	 		  ["SHA1","100","<a href=\"https:\/\/github.com\/pombredanne\/tokenizator\/blob\/master\/run\/sample\/java\/AdvancedPreferences.java\" target=\"_blank\">github:pombredanne\/tokenizator.zip::pombredanne-tokenizator-1a68652\/run\/sample\/java\/AdvancedPreferences.java<\/a>"]
	 		 ]
	 },
	 {
	   filename: "./adblockplusandroid-2014-06-01/src/org/adblockplus/android/AndroidFilterChangeCallback.java (GPL-3.0)",
	   matches_bin: [
	 		  ["SHA1","100","<a href=\"https:\/\/github.com\/pombredanne\/tokenizator\/blob\/master\/run\/sample\/java\/AndroidFilterChangeCallback.java\" target=\"_blank\">github:pombredanne\/tokenizator.zip::pombredanne-tokenizator-1a68652\/run\/sample\/java\/AndroidFilterChangeCallback.java<\/a>"]
	 		 ]
	 },
	 {
	   filename: "./adblockplusandroid-2014-06-01/src/org/adblockplus/android/AndroidLogSystem.java (GPL-3.0)",
	   matches_bin: [
	 		  ["SHA1","100","<a href=\"https:\/\/github.com\/pombredanne\/tokenizator\/blob\/master\/run\/sample\/java\/AndroidLogSystem.java\" target=\"_blank\">github:pombredanne\/tokenizator.zip::pombredanne-tokenizator-1a68652\/run\/sample\/java\/AndroidLogSystem.java<\/a>"]
	 		 ]
	 },
	 {
	   filename: "./adblockplusandroid-2014-06-01/src/org/adblockplus/android/AndroidUpdateAvailableCallback.java (GPL-3.0)",
	   matches_bin: [
	 		  ["SHA1","100","<a href=\"https:\/\/github.com\/pombredanne\/tokenizator\/blob\/master\/run\/sample\/java\/AndroidUpdateAvailableCallback.java\" target=\"_blank\">github:pombredanne\/tokenizator.zip::pombredanne-tokenizator-1a68652\/run\/sample\/java\/AndroidUpdateAvailableCallback.java<\/a>"]
	 		 ]
	 },
	 {
	   filename: "./adblockplusandroid-2014-06-01/src/org/adblockplus/android/AndroidUpdaterCallback.java (GPL-3.0)",
	   matches_bin: [
	 		  ["SHA1","100","<a href=\"https:\/\/github.com\/pombredanne\/tokenizator\/blob\/master\/run\/sample\/java\/AndroidUpdaterCallback.java\" target=\"_blank\">github:pombredanne\/tokenizator.zip::pombredanne-tokenizator-1a68652\/run\/sample\/java\/AndroidUpdaterCallback.java<\/a>"]
	 		 ]
	 },
	 {
	   filename: "./adblockplusandroid-2014-06-01/src/org/adblockplus/android/AndroidWebRequest.java (GPL-3.0)",
	   matches_bin: [
	 		  ["SHA1","100","<a href=\"https:\/\/github.com\/pombredanne\/tokenizator\/blob\/master\/run\/sample\/java\/AndroidWebRequest.java\" target=\"_blank\">github:pombredanne\/tokenizator.zip::pombredanne-tokenizator-1a68652\/run\/sample\/java\/AndroidWebRequest.java<\/a>"]
	 		 ]
	 },
	 {
	   filename: "./adblockplusandroid-2014-06-01/src/org/adblockplus/android/ConfigurationActivity.java (GPL-3.0)",
	   matches_bin: [
	 		  ["SHA1","100","<a href=\"https:\/\/github.com\/pombredanne\/tokenizator\/blob\/master\/run\/sample\/java\/ConfigurationActivity.java\" target=\"_blank\">github:pombredanne\/tokenizator.zip::pombredanne-tokenizator-1a68652\/run\/sample\/java\/ConfigurationActivity.java<\/a>"]
	 		 ]
	 },
	 {
	   filename: "./adblockplusandroid-2014-06-01/src/org/adblockplus/android/CrashHandler.java (GPL-3.0)",
	   matches_bin: [
	 		  ["SHA1","100","<a href=\"https:\/\/github.com\/pombredanne\/tokenizator\/blob\/master\/run\/sample\/java\/CrashHandler.java\" target=\"_blank\">github:pombredanne\/tokenizator.zip::pombredanne-tokenizator-1a68652\/run\/sample\/java\/CrashHandler.java<\/a>"]
	 		 ]
	 },
	 {
	   filename: "./adblockplusandroid-2014-06-01/src/org/adblockplus/android/CrashReportDialog.java (GPL-3.0)",
	   matches_bin: [
	 		  ["SHA1","100","<a href=\"https:\/\/github.com\/pombredanne\/tokenizator\/blob\/master\/run\/sample\/java\/CrashReportDialog.java\" target=\"_blank\">github:pombredanne\/tokenizator.zip::pombredanne-tokenizator-1a68652\/run\/sample\/java\/CrashReportDialog.java<\/a>"]
	 		 ],
	   matches_source: [  
	 	{ 
	 	  lines: "48..177",
	 	  code: "public final class CrashReportDialog extends Activity\n{\n  private static final String TAG = Utils.getTag(CrashReportDialog.class);\n  private String report;\n\n  @Override\n  protected void onCreate(final Bundle savedInstanceState)\n  {\n    super.onCreate(savedInstanceState);\n    requestWindowFeature(Window.FEATURE_LEFT_ICON);\n    setContentView(R.layout.crashreport);\n\n    final Bundle extras = getIntent().getExtras();\n    if (extras == null)\n    {\n      finish();\n      return;\n    }\n    report = extras.getString(\"report\");\n\n    getWindow().setFeatureDrawableResource(Window.FEATURE_LEFT_ICON, android.R.drawable.ic_dialog_alert);\n  }\n\n  public void onOk(final View v)\n  {\n    final String comment = ((EditText) findViewById(R.id.comments)).getText().toString();\n\n    try\n    {\n      final String[] reportLines = report.split(System.getProperty(\"line.separator\"));\n      final int api = Integer.parseInt(reportLines[0]);\n      final int build = Integer.parseInt(reportLines[1]);\n\n      final XmlSerializer xmlSerializer = Xml.newSerializer();\n      final StringWriter writer = new StringWriter();\n\n      xmlSerializer.setOutput(writer);\n      xmlSerializer.startDocument(\"UTF-8\", true);\n      xmlSerializer.startTag(\"\", \"crashreport\");\n      xmlSerializer.attribute(\"\", \"version\", \"1\");\n      xmlSerializer.attribute(\"\", \"api\", String.valueOf(api));\n      xmlSerializer.attribute(\"\", \"build\", String.valueOf(build));\n      xmlSerializer.startTag(\"\", \"error\");\n      xmlSerializer.attribute(\"\", \"type\", reportLines[2]);\n      xmlSerializer.startTag(\"\", \"message\");\n      xmlSerializer.text(reportLines[3]);\n      xmlSerializer.endTag(\"\", \"message\");\n      xmlSerializer.startTag(\"\", \"stacktrace\");\n      final Pattern p = Pattern.compile(\"\\\\|\");\n      boolean hasCause = false;\n      int i = 4;\n      while (i &#60; reportLines.length)\n      {\n        if (\"cause\".equals(reportLines[i]))\n        {\n          xmlSerializer.endTag(\"\", \"stacktrace\");\n          xmlSerializer.startTag(\"\", \"cause\");\n          hasCause = true;\n          i++;\n          xmlSerializer.attribute(\"\", \"type\", reportLines[i]);\n          i++;\n          xmlSerializer.startTag(\"\", \"message\");\n          xmlSerializer.text(reportLines[i]);\n          i++;\n          xmlSerializer.endTag(\"\", \"message\");\n          xmlSerializer.startTag(\"\", \"stacktrace\");\n          continue;\n        }\n        Log.e(TAG, \"Line: \" + reportLines[i]);\n        final String[] element = TextUtils.split(reportLines[i], p);\n        xmlSerializer.startTag(\"\", \"frame\");\n        xmlSerializer.attribute(\"\", \"class\", element[0]);\n        xmlSerializer.attribute(\"\", \"method\", element[1]);\n        xmlSerializer.attribute(\"\", \"isnative\", element[2]);\n        xmlSerializer.attribute(\"\", \"file\", element[3]);\n        xmlSerializer.attribute(\"\", \"line\", element[4]);\n        xmlSerializer.endTag(\"\", \"frame\");\n        i++;\n      }\n      xmlSerializer.endTag(\"\", \"stacktrace\");\n      if (hasCause)\n        xmlSerializer.endTag(\"\", \"cause\");\n      xmlSerializer.endTag(\"\", \"error\");\n      xmlSerializer.startTag(\"\", \"comment\");\n      xmlSerializer.text(comment);\n      xmlSerializer.endTag(\"\", \"comment\");\n      xmlSerializer.endTag(\"\", \"crashreport\");\n      xmlSerializer.endDocument();\n\n      final String xml = writer.toString();\n      final HttpClient httpclient = new DefaultHttpClient();\n      final HttpPost httppost = new HttpPost(getString(R.string.crash_report_url));\n      httppost.setHeader(\"Content-Type\", \"text\/xml; charset=UTF-8\");\n      httppost.addHeader(\"X-Adblock-Plus\", \"yes\");\n      httppost.setEntity(new StringEntity(xml));\n      final HttpResponse httpresponse = httpclient.execute(httppost);\n      final StatusLine statusLine = httpresponse.getStatusLine();\n      Log.e(TAG, statusLine.getStatusCode() + \" \" + statusLine.getReasonPhrase());\n      Log.e(TAG, EntityUtils.toString(httpresponse.getEntity()));\n      if (statusLine.getStatusCode() != 200)\n        throw new ClientProtocolException();\n      final String response = EntityUtils.toString(httpresponse.getEntity());\n      if (!\"saved\".equals(response))\n        throw new ClientProtocolException();\n      deleteFile(CrashHandler.REPORT_FILE);\n    }\n    catch (final ClientProtocolException e)\n    {\n      Log.e(TAG, \"Failed to submit a crash\", e);\n      Toast.makeText(this, R.string.msg_crash_submission_failure, Toast.LENGTH_LONG).show();\n    }\n    catch (final IOException e)\n    {\n      Log.e(TAG, \"Failed to submit a crash\", e);\n      Toast.makeText(this, R.string.msg_crash_submission_failure, Toast.LENGTH_LONG).show();\n    }\n    catch (final Exception e)\n    {\n      Log.e(TAG, \"Failed to create report\", e);\n      \/\/ Assuming corrupted report file, just silently deleting it\n      deleteFile(CrashHandler.REPORT_FILE);\n    }\n    finish();\n  }\n\n  public void onCancel(final View v)\n  {\n    deleteFile(CrashHandler.REPORT_FILE);\n    finish();\n  }\n}\n",
	 	  similarity: [
	 		{
	 		  percent: 86,
	 		  lines: "71..170",
	 		  reference: "<a href=\"https:\/\/github.com\/pombredanne\/tokenizator\/blob\/master\/run\/sample\/java\/CrashReportDialog.java#L71-L170\" target=\"_blank\">github-2016:pombredanne\/tokenizator.zip::pombredanne-tokenizator-1a68652\/run\/sample\/java\/CrashReportDialog.java>>>71:170<\/a>"
	 		}
	 	  ]
	 	}
	   ]
	 },
	 {
	   filename: "./adblockplusandroid-2014-06-01/src/org/adblockplus/android/HelpfulCheckBoxPreference.java (GPL-3.0)",
	   matches_bin: [
	 		  ["SHA1","100","<a href=\"https:\/\/github.com\/pombredanne\/tokenizator\/blob\/master\/run\/sample\/java\/HelpfulCheckBoxPreference.java\" target=\"_blank\">github:pombredanne\/tokenizator.zip::pombredanne-tokenizator-1a68652\/run\/sample\/java\/HelpfulCheckBoxPreference.java<\/a>"]
	 		 ]
	 },
	 {
	   filename: "./adblockplusandroid-2014-06-01/src/org/adblockplus/android/Preferences.java (GPL-3.0)",
	   matches_bin: [
	 		  ["SHA1","100","<a href=\"https:\/\/github.com\/pombredanne\/tokenizator\/blob\/master\/run\/sample\/java\/Preferences.java\" target=\"_blank\">github:pombredanne\/tokenizator.zip::pombredanne-tokenizator-1a68652\/run\/sample\/java\/Preferences.java<\/a>"]
	 		 ]
	 },
	 {
	   filename: "./adblockplusandroid-2014-06-01/src/org/adblockplus/android/ProxyConfigurationActivity.java (GPL-3.0)",
	   matches_bin: [
	 		  ["SHA1","100","<a href=\"https:\/\/github.com\/pombredanne\/tokenizator\/blob\/master\/run\/sample\/java\/ProxyConfigurationActivity.java\" target=\"_blank\">github:pombredanne\/tokenizator.zip::pombredanne-tokenizator-1a68652\/run\/sample\/java\/ProxyConfigurationActivity.java<\/a>"]
	 		 ]
	 },
	 {
	   filename: "./adblockplusandroid-2014-06-01/src/org/adblockplus/android/ProxyService.java (GPL-3.0)",
	   matches_bin: [
	 		  ["SHA1","100","<a href=\"https:\/\/github.com\/pombredanne\/tokenizator\/blob\/master\/run\/sample\/java\/ProxyService.java\" target=\"_blank\">github:pombredanne\/tokenizator.zip::pombredanne-tokenizator-1a68652\/run\/sample\/java\/ProxyService.java<\/a>"]
	 		 ]
	 },
	 {
	   filename: "./adblockplusandroid-2014-06-01/src/org/adblockplus/android/ProxySettings.java (GPL-3.0)",
	   matches_bin: [
	 		  ["SHA1","100","<a href=\"https:\/\/github.com\/pombredanne\/tokenizator\/blob\/master\/run\/sample\/java\/ProxySettings.java\" target=\"_blank\">github:pombredanne\/tokenizator.zip::pombredanne-tokenizator-1a68652\/run\/sample\/java\/ProxySettings.java<\/a>"]
	 		 ]
	 },
	 {
	   filename: "./adblockplusandroid-2014-06-01/src/org/adblockplus/android/RefreshableListPreference.java (GPL-3.0)",
	   matches_bin: [
	 		  ["SHA1","100","<a href=\"https:\/\/github.com\/pombredanne\/tokenizator\/blob\/master\/run\/sample\/java\/RefreshableListPreference.java\" target=\"_blank\">github:pombredanne\/tokenizator.zip::pombredanne-tokenizator-1a68652\/run\/sample\/java\/RefreshableListPreference.java<\/a>"]
	 		 ]
	 },
	 {
	   filename: "./adblockplusandroid-2014-06-01/src/org/adblockplus/android/Starter.java (GPL-3.0)",
	   matches_bin: [
	 		  ["SHA1","100","<a href=\"https:\/\/github.com\/pombredanne\/tokenizator\/blob\/master\/run\/sample\/java\/Starter.java\" target=\"_blank\">github:pombredanne\/tokenizator.zip::pombredanne-tokenizator-1a68652\/run\/sample\/java\/Starter.java<\/a>"]
	 		 ],
	   matches_source: [  
	 	{ 
	 	  lines: "27..60",
	 	  code: "public class Starter extends BroadcastReceiver\n{\n\n  @Override\n  public void onReceive(final Context context, final Intent intent)\n  {\n    final String action = intent.getAction();\n    final SharedPreferences prefs = PreferenceManager.getDefaultSharedPreferences(context);\n    boolean enabled = prefs.getBoolean(context.getString(R.string.pref_enabled), false);\n    boolean proxyenabled = prefs.getBoolean(context.getString(R.string.pref_proxyenabled), true);\n    final boolean autoconfigured = prefs.getBoolean(context.getString(R.string.pref_proxyautoconfigured), false);\n    if (Intent.ACTION_PACKAGE_REPLACED.equals(action))\n    {\n      final String pkg = context.getApplicationInfo().packageName;\n      final boolean us = pkg.equals(intent.getData().getSchemeSpecificPart());\n      enabled &= us;\n      proxyenabled &= us;\n    }\n    if (Intent.ACTION_BOOT_COMPLETED.equals(action))\n    {\n      final boolean startAtBoot = prefs.getBoolean(context.getString(R.string.pref_startatboot), context.getResources().getBoolean(R.bool.def_startatboot));\n      enabled &= startAtBoot;\n      proxyenabled &= startAtBoot;\n    }\n    if (enabled)\n    {\n      final AdblockPlus application = AdblockPlus.getApplication();\n      application.setFilteringEnabled(true);\n      application.startEngine();\n    }\n    if (enabled || (proxyenabled && !autoconfigured))\n      context.startService(new Intent(context, ProxyService.class));\n  }\n\n}\n",
	 	  similarity: [
	 		{
	 		  percent: 89,
	 		  lines: "31..58",
	 		  reference: "<a href=\"https:\/\/github.com\/pombredanne\/tokenizator\/blob\/master\/run\/sample\/java\/Starter.java#L31-L58\" target=\"_blank\">github-2016:pombredanne\/tokenizator.zip::pombredanne-tokenizator-1a68652\/run\/sample\/java\/Starter.java>>>31:58<\/a>"
	 		}
	 	  ]
	 	}
	   ]
	 },
	 {
	   filename: "./adblockplusandroid-2014-06-01/src/org/adblockplus/android/Subscription.java (GPL-3.0)",
	   matches_bin: [
	 		  ["SHA1","100","<a href=\"https:\/\/github.com\/pombredanne\/tokenizator\/blob\/master\/run\/sample\/java\/Subscription.java\" target=\"_blank\">github:pombredanne\/tokenizator.zip::pombredanne-tokenizator-1a68652\/run\/sample\/java\/Subscription.java<\/a>"]
	 		 ]
	 },
	 {
	   filename: "./adblockplusandroid-2014-06-01/src/org/adblockplus/android/SubscriptionParser.java (GPL-3.0)",
	   matches_bin: [
	 		  ["SHA1","100","<a href=\"https:\/\/github.com\/pombredanne\/tokenizator\/blob\/master\/run\/sample\/java\/SubscriptionParser.java\" target=\"_blank\">github:pombredanne\/tokenizator.zip::pombredanne-tokenizator-1a68652\/run\/sample\/java\/SubscriptionParser.java<\/a>"]
	 		 ]
	 },
	 {
	   filename: "./adblockplusandroid-2014-06-01/src/org/adblockplus/android/SummarizedPreferences.java (GPL-3.0)",
	   matches_bin: [
	 		  ["SHA1","100","<a href=\"https:\/\/github.com\/pombredanne\/tokenizator\/blob\/master\/run\/sample\/java\/SummarizedPreferences.java\" target=\"_blank\">github:pombredanne\/tokenizator.zip::pombredanne-tokenizator-1a68652\/run\/sample\/java\/SummarizedPreferences.java<\/a>"]
	 		 ]
	 },
	 {
	   filename: "./adblockplusandroid-2014-06-01/src/org/adblockplus/libadblockplus/AdblockPlusException.java (GPL-3.0)",
	   matches_source: [  
	 	{ 
	 	  lines: "21..38",
	 	  code: "public class AdblockPlusException extends RuntimeException\n{\n  private static final long serialVersionUID = -8127654134450836743L;\n\n  public AdblockPlusException(final String message)\n  {\n    super(message);\n  }\n\n  public AdblockPlusException(final String message, final Throwable throwable)\n  {\n    super(message, throwable);\n  }\n\n  public AdblockPlusException(final Throwable throwable)\n  {\n    super(throwable);\n  }\n}\n",
	 	  similarity: [
	 		{
	 		  percent: 80,
	 		  lines: "5..22",
	 		  reference: "<a href=\"http:\/\/sourceforge.net\/projects\/iphoneanalyzer\" target=\"_blank\">sourceforge:iphoneanalyzer\/svn\/source.zip::iphoneanalyzer-code-70..in\/java\/com\/crypticbit\/ipa\/central\/FileParseException.java>>>5:22<\/a>"
	 		},
	 		{
	 		  percent: 85,
	 		  lines: "25..40",
	 		  reference: "<a href=\"https:\/\/code.google.com\/archive\/p\/retrovolley\/source\/default\/source\" target=\"_blank\">googlecode:retrovolley\/sourcecode\/retrovolley\/retrovolley\/src\/main\/java\/retrovolley\/converter\/ConversionException.java>>>25:40<\/a>"
	 		},
	 		{
	 		  percent: 98,
	 		  lines: "15..45",
	 		  reference: "<a href=\"https:\/\/code.google.com\/archive\/p\/myesper\/source\/default\/source\" target=\"_blank\">googlecode:myesper\/sourcecode\/myesper-read-only\/MyEsper\/src\/com\/espertech\/esper\/client\/ConfigurationException.java>>>15:45<\/a>"
	 		},
	 		{
	 		  percent: 85,
	 		  lines: "23..37",
	 		  reference: "<a href=\"https:\/\/code.google.com\/archive\/p\/magnetism\/source\/default\/source\" target=\"_blank\">googlecode:magnetism\/sourcecode\/magnetism-read-only\/dumbhippo\/trunk\/server\/src\/com\/dumbhippo\/tx\/RetryException.java>>>23:37<\/a>"
	 		},
	 		{
	 		  percent: 85,
	 		  lines: "23..37",
	 		  reference: "<a href=\"https:\/\/code.google.com\/archive\/p\/magnetism\/source\/default\/source\" target=\"_blank\">googlecode:magnetism\/sourcecode\/magnetism-read-only\/dumbhippo\/bra..roduction\/server\/src\/com\/dumbhippo\/tx\/RetryException.java>>>23:37<\/a>"
	 		}
	 	  ]
	 	}
	   ]
	 },
	 {
	   filename: "./adblockplusandroid-2014-06-01/src/org/apache/commons/lang/CharUtils.java (Apache-2.0)",
	   matches_bin: [
	 		  ["TLSH","98","<a href=\"https:\/\/code.google.com\/archive\/p\/experttrainingbuildsystems\/source\/default\/source\" target=\"_blank\">googlecode:experttrainingbuildsystems\/sourcecode\/experttrainingbu..commons-lang\/src\/main\/java\/org\/apache\/commons\/lang\/CharUtils.java<\/a>"],
	 		  ["TLSH","95","<a href=\"http:\/\/sourceforge.net\/projects\/jasperetl\" target=\"_blank\">sourceforge:jasperetl\/downloads\/JasperETL%202.3.1\/JasperETL-All-r..\/commons-lang-2.1\/src\/java\/org\/apache\/commons\/lang\/CharUtils.java<\/a>"],
	 		  ["TLSH","89","<a href=\"http:\/\/sourceforge.net\/projects\/ideastringmanip\" target=\"_blank\">sourceforge:ideastringmanip\/svn\/source.zip::ideastringmanip-code-..\/src\/main\/java\/osmedile\/intellij\/stringmanip\/utils\/CharUtils.java<\/a>"],
	 		  ["TLSH","82","<a href=\"https:\/\/code.google.com\/archive\/p\/krasa\/source\/default\/source\" target=\"_blank\">googlecode:krasa\/sourcecode\/krasa-read-only\/UsefulActionsIntellijPlugin\/src\/krasa\/usefulactions\/utils\/CharUtils.java<\/a>"]
	 		 ]
	 },
	 {
	   filename: "./adblockplusandroid-2014-06-01/src/org/apache/commons/lang/StringEscapeUtils.java (Apache-2.0)",
	   matches_bin: [
	 		  ["TLSH","90","<a href=\"https:\/\/code.google.com\/archive\/p\/acv-project\/source\/default\/source\" target=\"_blank\">googlecode:acv-project\/sourcecode\/acv-project-read-only\/aipo\/aipo..peed\/src\/main\/java\/org\/apache\/commons\/lang\/StringEscapeUtils.java<\/a>"],
	 		  ["TLSH","86","<a href=\"https:\/\/code.google.com\/archive\/p\/krasa\/source\/default\/source\" target=\"_blank\">googlecode:krasa\/sourcecode\/krasa-read-only\/UsefulActionsIntellijPlugin\/src\/krasa\/usefulactions\/utils\/StringEscapeUtil.java<\/a>"],
	 		  ["TLSH","85","<a href=\"http:\/\/sourceforge.net\/projects\/ideastringmanip\" target=\"_blank\">sourceforge:ideastringmanip\/svn\/source.zip::ideastringmanip-code-..in\/java\/osmedile\/intellij\/stringmanip\/utils\/StringEscapeUtil.java<\/a>"],
	 		  ["TLSH","81","<a href=\"https:\/\/code.google.com\/archive\/p\/experttrainingbuildsystems\/source\/default\/source\" target=\"_blank\">googlecode:experttrainingbuildsystems\/sourcecode\/experttrainingbu..lang\/src\/main\/java\/org\/apache\/commons\/lang\/StringEscapeUtils.java<\/a>"]
	 		 ]
	 },
	 {
	   filename: "./adblockplusandroid-2014-06-01/src/org/apache/commons/lang/StringUtils.java (Apache-2.0)",
	   matches_bin: [
	 		  ["TLSH","86","<a href=\"http:\/\/sourceforge.net\/projects\/net4j\" target=\"_blank\">sourceforge:net4j\/downloads\/Baselines\/emf-cdo-3.0-baseline.zip::p..urce_2.4.0.v201005080502\/org\/apache\/commons\/lang\/StringUtils.java<\/a>"],
	 		  ["TLSH","86","<a href=\"https:\/\/www.assembla.com\/spaces\/AK_SPack\" target=\"_blank\">assembla:AK_SPack\/1.9_Spack_GServer\/Spack_Commons\/libsrc\/commons-lang-2.4-sources.jar::org\/apache\/commons\/lang\/StringUtils.java<\/a>"],
	 		  ["TLSH","76","<a href=\"https:\/\/code.google.com\/archive\/p\/bluestome\/source\/default\/source\" target=\"_blank\">googlecode:bluestome\/sourcecode\/bluestome-read-only\/trunk\/LShouxinNet\/src\/main\/java\/org\/apache\/commons\/lang\/StringUtils.java<\/a>"]
	 		 ]
	 },
	 {
	   filename: "./adblockplusandroid-2014-06-01/src/sunlabs/brazil/properties/PropertiesList.java (SPL-1.0)",
	   matches_bin: [
	 		  ["SHA1","100","<a href=\"http:\/\/sourceforge.net\/projects\/n-a-w-s\" target=\"_blank\">sourceforge:n-a-w-s\/downloads\/-08-21-08\/brazil-21-Aug-08.jar::srcs\/sunlabs\/brazil\/properties\/PropertiesList.java<\/a>"],
	 		  ["TLSH","84","<a href=\"https:\/\/code.google.com\/archive\/p\/brazil-on-appengine\/source\/default\/source\" target=\"_blank\">googlecode:brazil-on-appengine\/sourcecode\/brazil-on-appengine\/src\/sunlabs\/brazil\/properties\/PropertiesList.java<\/a>"]
	 		 ]
	 },
	 {
	   filename: "./adblockplusandroid-2014-06-01/src/sunlabs/brazil/server/Connection.java (SPL-1.0)",
	   matches_bin: [
	 		  ["SHA1","100","<a href=\"http:\/\/sourceforge.net\/projects\/n-a-w-s\" target=\"_blank\">sourceforge:n-a-w-s\/downloads\/-08-21-08\/brazil-21-Aug-08.jar::srcs\/sunlabs\/brazil\/server\/Connection.java<\/a>"]
	 		 ],
	   matches_source: [  
	 	{ 
	 	  lines: "134..239",
	 	  code: "class Connection implements Runnable\n{\n    \/**\n     * The Server that created this handler.\n     *\/\n    Server server;\n\n    \/**\n     * The client socket.\n     *\/\n    Socket sock;\n    \n    \/**\n     * The current request state\n     *\/\n    Request request;\n\n    \/**\n     * Constructs a new Connection and starts it running.\n     *\/\n    Connection(Server server, Socket sock)\n    {\n\tthis.server = server;\n\tthis.sock = sock;\n\n\trequest = new Request(server, sock);\n    }\n\n    \/**\n     * Loop reading HTTP requests from the socket until there is an error,\n     * the client requests that the socket be closed, or the client exceeds\n     * the maximum number of requests allowed on a single socket.\n     *\/\n    public void\n    run()\n    {\n\ttry {\n\t    sock.setSoTimeout(server.timeout);\n\n\t    while (request.shouldKeepAlive()) {\n\t\tif (request.getRequest() == false) {\n\t\t    break;\n\t\t}\n\t\tserver.requestCount++;\n\t\tif (server.handler.respond(request) == false) {\n\t\t    request.sendError(404, null, request.url);\n\t\t}\n\t\trequest.out.flush();\n\t\tserver.log(Server.LOG_LOG, null, \"request done\");\n\t    }\n\t} catch (InterruptedIOException e) {\n\t    \/*\n\t     * A read timed out, or (rarely) this thread was interrupted.\n\t     *\n\t     * Thread.interrupt() generates an InterruptedIOException that\n\t     * cannot be 100% discriminated from an InterruptedIOException\n\t     * caused by a read timeout.\n\t     *\n\t     * Under jdk-1.1, a Thread.interrupt() call generates an\n\t     * InterruptedIOException with the detail message\n\t     * \"operation interrupted\".\n\t     *\n\t     * Under jdk-1.2, a Thread.interrupt() call generates an\n\t     * InterruptedIOException with the detail message\n\t     * \"Interrupted system call\".\n\t     *\n\t     * In order to make the automated test scripts easier to write\n\t     * and run under both jdk-1.2 and jdk-1.1, suppress the varying\n\t     * InterruptedIOException log messages due to Thread.interrupt(),\n\t     * which only happens when the server is being shut down by\n\t     * the test script anyhow.\n\t     *\/\n\n\t    String msg = e.getMessage();\n\t    if ((msg == null) || (msg.indexOf(\"terrupted\") &#60; 0)) { \n\t\trequest.sendError(408, msg, null);\n\t    }\n\t} catch (IOException e) {\n\t    \/*\n\t     * Expected exception, due to not being able to write back to\n\t     * client, etc.\n\t     *\/\n\t    server.log(Server.LOG_LOG, null, \"Connection broken by client: \" +\n\t\te.getMessage());\n\t    if (server.logLevel &#62;= Server.LOG_DIAGNOSTIC) {\n\t\te.printStackTrace();\n\t    }\n\t} catch (Exception e) {\n\t    \/* \n\t     * Unexpected exception.\n\t     *\/\n\n\t    if (server.logLevel &#62;= Server.LOG_DIAGNOSTIC) {\n\t\te.printStackTrace();\n\t    }\n\t    request.sendError(500, e.toString(), \"unexpected error\");\n\t} finally {\n\t    server.log(Server.LOG_INFORMATIONAL, null, \"socket close\");\n\t    try {\n\t    \trequest.out.flush();\n\t    } catch (IOException e) {}\n\t    try {\n\t\tsock.close();\n\t    } catch (IOException e) {}\n\t}\n    }\n}\n",
	 	  similarity: [
	 		{
	 		  percent: 81,
	 		  lines: "168..238",
	 		  reference: "<a href=\"http:\/\/sourceforge.net\/projects\/n-a-w-s\" target=\"_blank\">sourceforge:n-a-w-s\/downloads\/naws-07-29-2008\/brazil-29-Jul-08.jar::srcs\/sunlabs\/brazil\/server\/Connection.java>>>168:238<\/a>"
	 		},
	 		{
	 		  percent: 81,
	 		  lines: "168..238",
	 		  reference: "<a href=\"http:\/\/sourceforge.net\/projects\/n-a-w-s\" target=\"_blank\">sourceforge:n-a-w-s\/downloads\/-08-21-08\/brazil-21-Aug-08.jar::srcs\/sunlabs\/brazil\/server\/Connection.java>>>168:238<\/a>"
	 		},
	 		{
	 		  percent: 81,
	 		  lines: "168..238",
	 		  reference: "<a href=\"https:\/\/github.com\/mbooth101\/brazil\/blob\/master\/src\/main\/java\/sunlabs\/brazil\/server\/Connection.java#L168-L238\" target=\"_blank\">github-2016:mbooth101\/brazil.zip::mbooth101-brazil-566e1be\/src\/main\/java\/sunlabs\/brazil\/server\/Connection.java>>>168:238<\/a>"
	 		},
	 		{
	 		  percent: 81,
	 		  lines: "168..238",
	 		  reference: "<a href=\"https:\/\/github.com\/munum\/ad_counter\/blob\/master\/src\/sunlabs\/brazil\/server\/Connection.java#L168-L238\" target=\"_blank\">github-2016:munum\/ad_counter.zip::munum-ad_counter-de5405d\/src\/sunlabs\/brazil\/server\/Connection.java>>>168:238<\/a>"
	 		}
	 	  ]
	 	}
	   ]
	 },
	 {
	   filename: "./adblockplusandroid-2014-06-01/src/sunlabs/brazil/server/ChainHandler.java (SPL-1.0)",
	   matches_bin: [
	 		  ["SHA1","100","<a href=\"http:\/\/sourceforge.net\/projects\/n-a-w-s\" target=\"_blank\">sourceforge:n-a-w-s\/downloads\/-08-21-08\/brazil-21-Aug-08.jar::srcs\/sunlabs\/brazil\/server\/ChainHandler.java<\/a>"],
	 		  ["TLSH","94","<a href=\"https:\/\/code.google.com\/archive\/p\/brazil-on-appengine\/source\/default\/source\" target=\"_blank\">googlecode:brazil-on-appengine\/sourcecode\/brazil-on-appengine\/src\/sunlabs\/brazil\/server\/ChainHandler.java<\/a>"]
	 		 ]
	 },
	 {
	   filename: "./adblockplusandroid-2014-06-01/src/sunlabs/brazil/server/Handler.java (SPL-1.0)",
	   matches_bin: [
	 		  ["SHA1","100","<a href=\"http:\/\/sourceforge.net\/projects\/n-a-w-s\" target=\"_blank\">sourceforge:n-a-w-s\/downloads\/-08-21-08\/brazil-21-Aug-08.jar::srcs\/sunlabs\/brazil\/server\/Handler.java<\/a>"],
	 		  ["TLSH","91","<a href=\"https:\/\/code.google.com\/archive\/p\/brazil-on-appengine\/source\/default\/source\" target=\"_blank\">googlecode:brazil-on-appengine\/sourcecode\/brazil-on-appengine\/src\/sunlabs\/brazil\/server\/Handler.java<\/a>"]
	 		 ]
	 },
	 {
	   filename: "./adblockplusandroid-2014-06-01/src/sunlabs/brazil/server/Request.java (SPL-1.0)",
	   matches_bin: [
	 		  ["TLSH","92","<a href=\"http:\/\/sourceforge.net\/projects\/n-a-w-s\" target=\"_blank\">sourceforge:n-a-w-s\/downloads\/-08-21-08\/brazil-21-Aug-08.jar::srcs\/sunlabs\/brazil\/server\/Request.java<\/a>"],
	 		  ["TLSH","77","<a href=\"https:\/\/code.google.com\/archive\/p\/brazil-on-appengine\/source\/default\/source\" target=\"_blank\">googlecode:brazil-on-appengine\/sourcecode\/brazil-on-appengine\/src\/sunlabs\/brazil\/server\/Request.java<\/a>"]
	 		 ]
	 },
	 {
	   filename: "./adblockplusandroid-2014-06-01/src/sunlabs/brazil/server/Server.java (SPL-1.0)",
	   matches_bin: [
	 		  ["TLSH","96","<a href=\"http:\/\/sourceforge.net\/projects\/n-a-w-s\" target=\"_blank\">sourceforge:n-a-w-s\/downloads\/-08-21-08\/brazil-21-Aug-08.jar::srcs\/sunlabs\/brazil\/server\/Server.java<\/a>"],
	 		  ["TLSH","87","<a href=\"https:\/\/code.google.com\/archive\/p\/brazil-on-appengine\/source\/default\/source\" target=\"_blank\">googlecode:brazil-on-appengine\/sourcecode\/brazil-on-appengine\/src\/sunlabs\/brazil\/server\/Server.java<\/a>"]
	 		 ]
	 },
	 {
	   filename: "./adblockplusandroid-2014-06-01/src/sunlabs/brazil/util/Base64.java (SPL-1.0)",
	   matches_bin: [
	 		  ["TLSH","95","<a href=\"http:\/\/sourceforge.net\/projects\/n-a-w-s\" target=\"_blank\">sourceforge:n-a-w-s\/downloads\/-08-21-08\/brazil-21-Aug-08.jar::srcs\/sunlabs\/brazil\/util\/Base64.java<\/a>"],
	 		  ["TLSH","89","<a href=\"https:\/\/code.google.com\/archive\/p\/brazil-on-appengine\/source\/default\/source\" target=\"_blank\">googlecode:brazil-on-appengine\/sourcecode\/brazil-on-appengine\/src\/sunlabs\/brazil\/util\/Base64.java<\/a>"],
	 		  ["TLSH","79","<a href=\"https:\/\/code.google.com\/archive\/p\/sunspotcoursedev\/source\/default\/source\" target=\"_blank\">googlecode:sunspotcoursedev\/sourcecode\/sunspotcoursedev\/class-rep..s\/WebOfThings\/lib\/CHTTPlib\/src\/com\/sun\/spot\/wot\/utils\/Base64.java<\/a>"],
	 		  ["TLSH","75","<a href=\"https:\/\/code.google.com\/archive\/p\/onestonesoup\/source\/default\/source\" target=\"_blank\">googlecode:onestonesoup\/sourcecode\/onestonesoup\/Core\/src\/main\/java\/org\/onestonesoup\/core\/Base64.java<\/a>"]
	 		 ]
	 },
	 {
	   filename: "./adblockplusandroid-2014-06-01/src/sunlabs/brazil/util/Format.java (SPL-1.0)",
	   matches_bin: [
	 		  ["SHA1","100","<a href=\"http:\/\/sourceforge.net\/projects\/n-a-w-s\" target=\"_blank\">sourceforge:n-a-w-s\/downloads\/-08-21-08\/brazil-21-Aug-08.jar::srcs\/sunlabs\/brazil\/util\/Format.java<\/a>"],
	 		  ["TLSH","92","<a href=\"https:\/\/code.google.com\/archive\/p\/brazil-on-appengine\/source\/default\/source\" target=\"_blank\">googlecode:brazil-on-appengine\/sourcecode\/brazil-on-appengine\/src\/sunlabs\/brazil\/util\/Format.java<\/a>"]
	 		 ]
	 },
	 {
	   filename: "./adblockplusandroid-2014-06-01/src/sunlabs/brazil/util/Glob.java (SPL-1.0)",
	   matches_bin: [
	 		  ["SHA1","100","<a href=\"http:\/\/sourceforge.net\/projects\/n-a-w-s\" target=\"_blank\">sourceforge:n-a-w-s\/downloads\/-08-21-08\/brazil-21-Aug-08.jar::srcs\/sunlabs\/brazil\/util\/Glob.java<\/a>"]
	 		 ]
	 },
	 {
	   filename: "./adblockplusandroid-2014-06-01/src/sunlabs/brazil/util/http/HttpInputStream.java (SPL-1.0)",
	   matches_bin: [
	 		  ["SHA1","100","<a href=\"http:\/\/sourceforge.net\/projects\/n-a-w-s\" target=\"_blank\">sourceforge:n-a-w-s\/downloads\/-08-21-08\/brazil-21-Aug-08.jar::srcs\/sunlabs\/brazil\/util\/http\/HttpInputStream.java<\/a>"],
	 		  ["SHA1","100","<a href=\"https:\/\/code.google.com\/archive\/p\/brazil-on-appengine\/source\/default\/source\" target=\"_blank\">googlecode:brazil-on-appengine\/sourcecode\/brazil-on-appengine\/src\/sunlabs\/brazil\/util\/http\/HttpInputStream.java<\/a>"]
	 		 ]
	 },
	 {
	   filename: "./adblockplusandroid-2014-06-01/src/sunlabs/brazil/util/http/HttpRequest.java (SPL-1.0)",
	   matches_bin: [
	 		  ["TLSH","85","<a href=\"http:\/\/sourceforge.net\/projects\/n-a-w-s\" target=\"_blank\">sourceforge:n-a-w-s\/downloads\/-08-21-08\/brazil-21-Aug-08.jar::srcs\/sunlabs\/brazil\/util\/http\/HttpRequest.java<\/a>"]
	 		 ]
	 },
	 {
	   filename: "./adblockplusandroid-2014-06-01/src/sunlabs/brazil/util/http/HttpSocket.java (SPL-1.0)",
	   matches_bin: [
	 		  ["SHA1","100","<a href=\"http:\/\/sourceforge.net\/projects\/n-a-w-s\" target=\"_blank\">sourceforge:n-a-w-s\/downloads\/-08-21-08\/brazil-21-Aug-08.jar::srcs\/sunlabs\/brazil\/util\/http\/HttpSocket.java<\/a>"]
	 		 ]
	 },
	 {
	   filename: "./adblockplusandroid-2014-06-01/src/sunlabs/brazil/util/http/HttpSocketPool.java (SPL-1.0)",
	   matches_bin: [
	 		  ["SHA1","100","<a href=\"http:\/\/sourceforge.net\/projects\/n-a-w-s\" target=\"_blank\">sourceforge:n-a-w-s\/downloads\/-08-21-08\/brazil-21-Aug-08.jar::srcs\/sunlabs\/brazil\/util\/http\/HttpSocketPool.java<\/a>"]
	 		 ]
	 },
	 {
	   filename: "./adblockplusandroid-2014-06-01/src/sunlabs/brazil/util/http/HttpUtil.java (SPL-1.0)",
	   matches_bin: [
	 		  ["TLSH","96","<a href=\"http:\/\/sourceforge.net\/projects\/n-a-w-s\" target=\"_blank\">sourceforge:n-a-w-s\/downloads\/-08-21-08\/brazil-21-Aug-08.jar::srcs\/sunlabs\/brazil\/util\/http\/HttpUtil.java<\/a>"],
	 		  ["TLSH","90","<a href=\"https:\/\/code.google.com\/archive\/p\/brazil-on-appengine\/source\/default\/source\" target=\"_blank\">googlecode:brazil-on-appengine\/sourcecode\/brazil-on-appengine\/src\/sunlabs\/brazil\/util\/http\/HttpUtil.java<\/a>"]
	 		 ]
	 },
	 {
	   filename: "./adblockplusandroid-2014-06-01/src/sunlabs/brazil/util/http/MimeHeaders.java (SPL-1.0)",
	   matches_bin: [
	 		  ["SHA1","100","<a href=\"http:\/\/sourceforge.net\/projects\/n-a-w-s\" target=\"_blank\">sourceforge:n-a-w-s\/downloads\/-08-21-08\/brazil-21-Aug-08.jar::srcs\/sunlabs\/brazil\/util\/http\/MimeHeaders.java<\/a>"],
	 		  ["SHA1","100","<a href=\"https:\/\/code.google.com\/archive\/p\/brazil-on-appengine\/source\/default\/source\" target=\"_blank\">googlecode:brazil-on-appengine\/sourcecode\/brazil-on-appengine\/src\/sunlabs\/brazil\/util\/http\/MimeHeaders.java<\/a>"]
	 		 ]
	 },
	 {
	   filename: "./adblockplusandroid-2014-06-01/src/sunlabs/brazil/util/MatchString.java (SPL-1.0)",
	   matches_bin: [
	 		  ["TLSH","89","<a href=\"http:\/\/sourceforge.net\/projects\/n-a-w-s\" target=\"_blank\">sourceforge:n-a-w-s\/downloads\/-08-21-08\/brazil-21-Aug-08.jar::srcs\/sunlabs\/brazil\/util\/MatchString.java<\/a>"],
	 		  ["TLSH","83","<a href=\"https:\/\/code.google.com\/archive\/p\/brazil-on-appengine\/source\/default\/source\" target=\"_blank\">googlecode:brazil-on-appengine\/sourcecode\/brazil-on-appengine\/src\/sunlabs\/brazil\/util\/MatchString.java<\/a>"]
	 		 ]
	 },
	 {
	   filename: "./adblockplusandroid-2014-06-01/src/sunlabs/brazil/util/regexp/Regexp.java (SPL-1.0)",
	   matches_bin: [
	 		  ["SHA1","100","<a href=\"http:\/\/sourceforge.net\/projects\/n-a-w-s\" target=\"_blank\">sourceforge:n-a-w-s\/downloads\/-08-21-08\/brazil-21-Aug-08.jar::srcs\/sunlabs\/brazil\/util\/regexp\/Regexp.java<\/a>"],
	 		  ["TLSH","96","<a href=\"https:\/\/code.google.com\/archive\/p\/brazil-on-appengine\/source\/default\/source\" target=\"_blank\">googlecode:brazil-on-appengine\/sourcecode\/brazil-on-appengine\/src\/sunlabs\/brazil\/util\/regexp\/Regexp.java<\/a>"]
	 		 ]
	 },
	 {
	   filename: "./adblockplusandroid-2014-06-01/src/sunlabs/brazil/util/SocketFactory.java (SPL-1.0)",
	   matches_bin: [
	 		  ["SHA1","100","<a href=\"http:\/\/sourceforge.net\/projects\/n-a-w-s\" target=\"_blank\">sourceforge:n-a-w-s\/downloads\/-08-21-08\/brazil-21-Aug-08.jar::srcs\/sunlabs\/brazil\/util\/SocketFactory.java<\/a>"]
	 		 ]
	 },
	 {
	   filename: "./adblockplusandroid-2014-06-01/src/sunlabs/brazil/util/regexp/Regsub.java (SPL-1.0)",
	   matches_bin: [
	 		  ["SHA1","100","<a href=\"http:\/\/sourceforge.net\/projects\/n-a-w-s\" target=\"_blank\">sourceforge:n-a-w-s\/downloads\/-08-21-08\/brazil-21-Aug-08.jar::srcs\/sunlabs\/brazil\/util\/regexp\/Regsub.java<\/a>"],
	 		  ["TLSH","91","<a href=\"https:\/\/code.google.com\/archive\/p\/brazil-on-appengine\/source\/default\/source\" target=\"_blank\">googlecode:brazil-on-appengine\/sourcecode\/brazil-on-appengine\/src\/sunlabs\/brazil\/util\/regexp\/Regsub.java<\/a>"]
	 		 ]
	 },
	 {
	   filename: "./adblockplusandroid-2014-06-01/src/sunlabs/brazil/util/StringMap.java (SPL-1.0)",
	   matches_bin: [
	 		  ["TLSH","96","<a href=\"http:\/\/sourceforge.net\/projects\/n-a-w-s\" target=\"_blank\">sourceforge:n-a-w-s\/downloads\/-08-21-08\/brazil-21-Aug-08.jar::srcs\/sunlabs\/brazil\/util\/StringMap.java<\/a>"],
	 		  ["TLSH","85","<a href=\"https:\/\/code.google.com\/archive\/p\/brazil-on-appengine\/source\/default\/source\" target=\"_blank\">googlecode:brazil-on-appengine\/sourcecode\/brazil-on-appengine\/src\/sunlabs\/brazil\/util\/StringMap.java<\/a>"]
	 		 ]
	 },
	 {
	   filename: "./big/src/big/BigZip.java (EUPL-1.1)",
	   matches_bin: [
	 		  ["TLSH","79","<a href=\"https:\/\/github.com\/pombredanne\/f2f\/blob\/master\/src\/big\/ArchiveBIG.java\" target=\"_blank\">github:pombredanne\/f2f.zip::pombredanne-f2f-59cd2d3\/src\/big\/ArchiveBIG.java<\/a>"]
	 		 ]
	 },
	 {
	   filename: "./big/src/big/zip.java (EUPL-1.1)",
	   matches_bin: [
	 		  ["SHA1","100","<a href=\"https:\/\/github.com\/pombredanne\/f2f\/blob\/master\/src\/big\/zip.java\" target=\"_blank\">github:pombredanne\/f2f.zip::pombredanne-f2f-59cd2d3\/src\/big\/zip.java<\/a>"]
	 		 ]
	 }
  ]
 },
 {
  type: "script",
  files: [
	 {
	   filename: "./adblockplusandroid-2014-06-01/assets/js/basedomain.js (MIT)",
	   matches_bin: [
	 		  ["SHA1","100","<a href=\"https:\/\/github.com\/freegraphy\/etao-projects\/blob\/master\/tools-adblock-plus\/lib\/basedomain.js\" target=\"_blank\">github:freegraphy\/etao-projects.zip::freegraphy-etao-projects-74738fc\/tools-adblock-plus\/lib\/basedomain.js<\/a>"]
	 		 ]
	 },
	 {
	   filename: "./adblockplusandroid-2014-06-01/assets/js/ElemHide.jsm (GPL-3.0)",
	   matches_bin: [
	 		  ["SHA1","100","<a href=\"https:\/\/github.com\/munum\/ad_counter\/blob\/master\/assets\/js\/ElemHide.jsm\" target=\"_blank\">github:munum\/ad_counter.zip::munum-ad_counter-de5405d\/assets\/js\/ElemHide.jsm<\/a>"]
	 		 ]
	 },
	 {
	   filename: "./adblockplusandroid-2014-06-01/assets/js/FilterClasses.jsm (GPL-3.0)",
	   matches_bin: [
	 		  ["SHA1","100","<a href=\"https:\/\/github.com\/munum\/ad_counter\/blob\/master\/assets\/js\/FilterClasses.jsm\" target=\"_blank\">github:munum\/ad_counter.zip::munum-ad_counter-de5405d\/assets\/js\/FilterClasses.jsm<\/a>"]
	 		 ]
	 },
	 {
	   filename: "./adblockplusandroid-2014-06-01/assets/js/FilterListener.jsm (GPL-3.0)",
	   matches_bin: [
	 		  ["SHA1","100","<a href=\"https:\/\/github.com\/munum\/ad_counter\/blob\/master\/assets\/js\/FilterListener.jsm\" target=\"_blank\">github:munum\/ad_counter.zip::munum-ad_counter-de5405d\/assets\/js\/FilterListener.jsm<\/a>"]
	 		 ]
	 },
	 {
	   filename: "./adblockplusandroid-2014-06-01/assets/js/FilterNotifier.jsm (GPL-3.0)",
	   matches_bin: [
	 		  ["SHA1","100","<a href=\"https:\/\/github.com\/munum\/ad_counter\/blob\/master\/assets\/js\/FilterNotifier.jsm\" target=\"_blank\">github:munum\/ad_counter.zip::munum-ad_counter-de5405d\/assets\/js\/FilterNotifier.jsm<\/a>"]
	 		 ]
	 },
	 {
	   filename: "./adblockplusandroid-2014-06-01/assets/js/Matcher.jsm (GPL-3.0)",
	   matches_bin: [
	 		  ["SHA1","100","<a href=\"https:\/\/github.com\/munum\/ad_counter\/blob\/master\/assets\/js\/Matcher.jsm\" target=\"_blank\">github:munum\/ad_counter.zip::munum-ad_counter-de5405d\/assets\/js\/Matcher.jsm<\/a>"]
	 		 ]
	 },
	 {
	   filename: "./adblockplusandroid-2014-06-01/assets/js/FilterStorage.jsm (GPL-3.0)",
	   matches_bin: [
	 		  ["SHA1","100","<a href=\"https:\/\/github.com\/munum\/ad_counter\/blob\/master\/assets\/js\/FilterStorage.jsm\" target=\"_blank\">github:munum\/ad_counter.zip::munum-ad_counter-de5405d\/assets\/js\/FilterStorage.jsm<\/a>"]
	 		 ]
	 },
	 {
	   filename: "./adblockplusandroid-2014-06-01/assets/js/publicSuffixList.js (GPL-3.0)",
	   matches_bin: [
	 		  ["SHA1","100","<a href=\"https:\/\/github.com\/freegraphy\/etao-projects\/blob\/master\/tools-adblock-plus\/lib\/publicSuffixList.js\" target=\"_blank\">github:freegraphy\/etao-projects.zip::freegraphy-etao-projects-74738fc\/tools-adblock-plus\/lib\/publicSuffixList.js<\/a>"]
	 		 ]
	 },
	 {
	   filename: "./adblockplusandroid-2014-06-01/assets/js/punycode.js (MIT)",
	   matches_bin: [
	 		  ["TLSH","94","<a href=\"http:\/\/sourceforge.net\/projects\/ameram\" target=\"_blank\">sourceforge:ameram\/downloads\/DumpPRJ.zip::ram\/assets\/215291e2\/punycode.js<\/a>"],
	 		  ["TLSH","94","<a href=\"https:\/\/code.google.com\/archive\/p\/ict-webpage-for-jcus-rep-lab\/source\/default\/source\" target=\"_blank\">googlecode:ict-webpage-for-jcus-rep-lab\/sourcecode\/ict-webpage-fo.. for jcus rep poly shared lab\/college\/assets\/e4779210\/punycode.js<\/a>"],
	 		  ["TLSH","86","<a href=\"https:\/\/code.google.com\/archive\/p\/ict-webpage-for-jcus-rep-lab\/source\/default\/source\" target=\"_blank\">googlecode:ict-webpage-for-jcus-rep-lab\/sourcecode\/ict-webpage-fo.. for jcus rep poly shared lab\/college\/assets\/bc5537e7\/punycode.js<\/a>"]
	 		 ]
	 },
	 {
	   filename: "./adblockplusandroid-2014-06-01/assets/js/start.js (GPL-3.0)",
	   matches_bin: [
	 		  ["SHA1","100","<a href=\"https:\/\/github.com\/munum\/ad_counter\/blob\/master\/assets\/js\/start.js\" target=\"_blank\">github:munum\/ad_counter.zip::munum-ad_counter-de5405d\/assets\/js\/start.js<\/a>"]
	 		 ]
	 },
	 {
	   filename: "./adblockplusandroid-2014-06-01/assets/js/SubscriptionClasses.jsm (GPL-3.0)",
	   matches_bin: [
	 		  ["SHA1","100","<a href=\"https:\/\/github.com\/munum\/ad_counter\/blob\/master\/assets\/js\/SubscriptionClasses.jsm\" target=\"_blank\">github:munum\/ad_counter.zip::munum-ad_counter-de5405d\/assets\/js\/SubscriptionClasses.jsm<\/a>"]
	 		 ]
	 },
	 {
	   filename: "./adblockplusandroid-2014-06-01/assets/js/Synchronizer.jsm (GPL-3.0)",
	   matches_bin: [
	 		  ["SHA1","100","<a href=\"https:\/\/github.com\/munum\/ad_counter\/blob\/master\/assets\/js\/Synchronizer.jsm\" target=\"_blank\">github:munum\/ad_counter.zip::munum-ad_counter-de5405d\/assets\/js\/Synchronizer.jsm<\/a>"]
	 		 ]
	 },
	 {
	   filename: "./adblockplusandroid-2014-06-01/assets/js/XMLHttpRequest.jsm (GPL-3.0)",
	   matches_bin: [
	 		  ["SHA1","100","<a href=\"https:\/\/github.com\/munum\/ad_counter\/blob\/master\/assets\/js\/XMLHttpRequest.jsm\" target=\"_blank\">github:munum\/ad_counter.zip::munum-ad_counter-de5405d\/assets\/js\/XMLHttpRequest.jsm<\/a>"]
	 		 ]
	 }
  ]
 },
 {
  type: "image",
  files: [
	 {
	   filename: "./adblockplusandroid-2014-06-01/res/drawable/transparent.png (GPL-3.0)",
	   matches_bin: [
	 		  ["SHA1","100","<a href=\"https:\/\/code.google.com\/archive\/p\/remuco\/source\/default\/source\" target=\"_blank\">googlecode:remuco\/sourcecode\/remuco\/client\/midp\/res\/icons\/uni\/remuco_0.png<\/a>"]
	 		 ]
	 },
	 {
	   filename: "./adblockplusandroid-2014-06-01/res/drawable-hdpi/ic_menu_help.png (GPL-3.0)",
	   matches_bin: [
	 		  ["SHA1","100","<a href=\"http:\/\/sourceforge.net\/projects\/entomologist\" target=\"_blank\">sourceforge:entomologist\/git\/source.zip::entomologist-code-44baa9..6f176040c4a52e38cf\/mobile\/Trac\/res\/drawable-hdpi\/ic_menu_help.png<\/a>"],
	 		  ["SHA1","100","<a href=\"https:\/\/code.google.com\/archive\/p\/hs-bremen-guide\/source\/default\/source\" target=\"_blank\">googlecode:hs-bremen-guide\/sourcecode\/hs-bremen-guide-read-only\/HS-Bremen-Guide\/res\/drawable-hdpi\/ic_menu_help.png<\/a>"],
	 		  ["SHA1","100","<a href=\"http:\/\/track.codeplex.com\/SourceControl\/latest#res\/drawable-hdpi\/ic_menu_help.png\" target=\"_blank\">codeplex:track\/track-1d90753506dd6c00d2f3f6bf0758cd8a428c5e86.zip::res\/drawable-hdpi\/ic_menu_help.png<\/a>"]
	 		 ]
	 },
	 {
	   filename: "./adblockplusandroid-2014-06-01/res/drawable-hdpi/ic_menu_info_details.png (GPL-3.0)",
	   matches_bin: [
	 		  ["SHA1","100","<a href=\"http:\/\/sourceforge.net\/projects\/androidperiodic\" target=\"_blank\">sourceforge:androidperiodic\/hg\/source.zip::androidperiodic-code-0..cce2f671e9186c86e7f2f6\/res\/drawable-hdpi\/ic_menu_info_details.png<\/a>"],
	 		  ["SHA1","100","<a href=\"https:\/\/code.google.com\/archive\/p\/hs-bremen-guide\/source\/default\/source\" target=\"_blank\">googlecode:hs-bremen-guide\/sourcecode\/hs-bremen-guide-read-only\/HS-Bremen-Guide\/res\/drawable-hdpi\/ic_menu_info_details.png<\/a>"],
	 		  ["SHA1","100","<a href=\"http:\/\/track.codeplex.com\/SourceControl\/latest#res\/drawable-hdpi\/ic_menu_info_details.png\" target=\"_blank\">codeplex:track\/track-1d90753506dd6c00d2f3f6bf0758cd8a428c5e86.zip::res\/drawable-hdpi\/ic_menu_info_details.png<\/a>"]
	 		 ]
	 },
	 {
	   filename: "./adblockplusandroid-2014-06-01/res/drawable-hdpi/ic_menu_preferences.png (GPL-3.0)",
	   matches_bin: [
	 		  ["SHA1","100","<a href=\"http:\/\/sourceforge.net\/projects\/androidterm\" target=\"_blank\">sourceforge:androidterm\/downloads\/Android-Terminal-Emulator-maste..nal-Emulator-master\/res\/drawable-hdpi-v11\/ic_menu_preferences.png<\/a>"],
	 		  ["SHA1","100","<a href=\"https:\/\/code.google.com\/archive\/p\/passdroid\/source\/default\/source\" target=\"_blank\">googlecode:passdroid\/sourcecode\/passdroid\/res\/drawable-hdpi\/ic_menu_preferences.png<\/a>"],
	 		  ["SHA1","100","<a href=\"https:\/\/github.com\/fling-mstar\/development\/blob\/master\/samples\/AndroidBeamDemo\/res\/drawable-hdpi\/ic_menu_preferences.png\" target=\"_blank\">github:fling-mstar\/development.zip::fling-mstar-development-f8c2c..samples\/AndroidBeamDemo\/res\/drawable-hdpi\/ic_menu_preferences.png<\/a>"]
	 		 ]
	 },
	 {
	   filename: "./adblockplusandroid-2014-06-01/res/drawable-hdpi/ic_menu_refresh.png (GPL-3.0)",
	   matches_bin: [
	 		  ["SHA1","100","<a href=\"http:\/\/sourceforge.net\/projects\/entomologist\" target=\"_blank\">sourceforge:entomologist\/git\/source.zip::entomologist-code-44baa9..76040c4a52e38cf\/mobile\/Trac\/res\/drawable-hdpi\/ic_menu_refresh.png<\/a>"],
	 		  ["SHA1","100","<a href=\"https:\/\/code.google.com\/archive\/p\/wifi-unlocker\/source\/default\/source\" target=\"_blank\">googlecode:wifi-unlocker\/sourcecode\/wifi-unlocker-read-only\/res\/drawable-hdpi\/ic_menu_refresh.png<\/a>"],
	 		  ["SHA1","100","<a href=\"http:\/\/selvinlistsyncsample.codeplex.com\/SourceControl\/latest#selvinlistsyncsample_5ea4839099e3\/sample\/res\/drawable-hdpi\/ic_menu_refresh.png\" target=\"_blank\">codeplex:selvinlistsyncsample\/selvinlistsyncsample-5ea4839099e3.z..csample_5ea4839099e3\/sample\/res\/drawable-hdpi\/ic_menu_refresh.png<\/a>"]
	 		 ]
	 },
	 {
	   filename: "./adblockplusandroid-2014-06-01/res/drawable-ldpi/ic_menu_help.png (GPL-3.0)",
	   matches_bin: [
	 		  ["SHA1","100","<a href=\"http:\/\/sourceforge.net\/projects\/entomologist\" target=\"_blank\">sourceforge:entomologist\/git\/source.zip::entomologist-code-44baa9..6f176040c4a52e38cf\/mobile\/Trac\/res\/drawable-ldpi\/ic_menu_help.png<\/a>"],
	 		  ["SHA1","100","<a href=\"https:\/\/code.google.com\/archive\/p\/fullreaderplus\/source\/default\/source\" target=\"_blank\">googlecode:fullreaderplus\/sourcecode\/fullreaderplus-read-only\/FullReader+\/Reader\/res\/drawable-ldpi\/ic_menu_help.png<\/a>"],
	 		  ["SHA1","100","<a href=\"http:\/\/lampguiden.codeplex.com\/SourceControl\/latest#Main\/Android Source\/res\/drawable-ldpi\/ic_menu_help.png\" target=\"_blank\">codeplex:lampguiden\/lampguiden-40849.zip::Main\/Android Source\/res\/drawable-ldpi\/ic_menu_help.png<\/a>"]
	 		 ]
	 },
	 {
	   filename: "./adblockplusandroid-2014-06-01/res/drawable-ldpi/ic_menu_info_details.png (GPL-3.0)",
	   matches_bin: [
	 		  ["SHA1","100","<a href=\"http:\/\/sourceforge.net\/projects\/androidperiodic\" target=\"_blank\">sourceforge:androidperiodic\/hg\/source.zip::androidperiodic-code-0..cce2f671e9186c86e7f2f6\/res\/drawable-ldpi\/ic_menu_info_details.png<\/a>"],
	 		  ["SHA1","100","<a href=\"https:\/\/code.google.com\/archive\/p\/fullreaderplus\/source\/default\/source\" target=\"_blank\">googlecode:fullreaderplus\/sourcecode\/fullreaderplus-read-only\/FullReader+\/Reader\/res\/drawable-ldpi\/ic_menu_info_details.png<\/a>"],
	 		  ["SHA1","100","<a href=\"https:\/\/github.com\/fqiao\/NFCard\/blob\/master\/res\/drawable-ldpi\/ic_menu_about.png\" target=\"_blank\">github:fqiao\/NFCard.zip::fqiao-NFCard-3da4f6e\/res\/drawable-ldpi\/ic_menu_about.png<\/a>"]
	 		 ]
	 },
	 {
	   filename: "./adblockplusandroid-2014-06-01/res/drawable-ldpi/ic_menu_preferences.png (GPL-3.0)",
	   matches_bin: [
	 		  ["SHA1","100","<a href=\"http:\/\/sourceforge.net\/projects\/androidterm\" target=\"_blank\">sourceforge:androidterm\/downloads\/Android-Terminal-Emulator-maste..nal-Emulator-master\/res\/drawable-ldpi-v11\/ic_menu_preferences.png<\/a>"],
	 		  ["SHA1","100","<a href=\"https:\/\/code.google.com\/archive\/p\/fullreaderplus\/source\/default\/source\" target=\"_blank\">googlecode:fullreaderplus\/sourcecode\/fullreaderplus-read-only\/FullReader+\/Reader\/res\/drawable-ldpi\/ic_menu_preferences.png<\/a>"],
	 		  ["SHA1","100","<a href=\"https:\/\/github.com\/fx2000\/opendatakit.collect\/blob\/master\/res\/drawable-ldpi\/ic_menu_preferences.png\" target=\"_blank\">github:fx2000\/opendatakit.collect.zip::fx2000-opendatakit.collect-e251edd\/res\/drawable-ldpi\/ic_menu_preferences.png<\/a>"]
	 		 ]
	 },
	 {
	   filename: "./adblockplusandroid-2014-06-01/res/drawable-ldpi/ic_menu_refresh.png (GPL-3.0)",
	   matches_bin: [
	 		  ["SHA1","100","<a href=\"http:\/\/sourceforge.net\/projects\/andcarmonitor\" target=\"_blank\">sourceforge:andcarmonitor\/downloads\/source\/CarMonitorClient.zip::CarMonitorClient\/res\/drawable-ldpi\/ic_menu_refresh.png<\/a>"],
	 		  ["SHA1","100","<a href=\"https:\/\/code.google.com\/archive\/p\/tunesremote-plus\/source\/default\/source\" target=\"_blank\">googlecode:tunesremote-plus\/sourcecode\/tunesremote-plus-read-only\/res\/drawable-ldpi\/ic_menu_refresh.png<\/a>"],
	 		  ["SHA1","100","<a href=\"http:\/\/selvinlistsyncsample.codeplex.com\/SourceControl\/latest#selvinlistsyncsample_5ea4839099e3\/sample\/res\/drawable-ldpi\/ic_menu_refresh.png\" target=\"_blank\">codeplex:selvinlistsyncsample\/selvinlistsyncsample-5ea4839099e3.z..csample_5ea4839099e3\/sample\/res\/drawable-ldpi\/ic_menu_refresh.png<\/a>"]
	 		 ]
	 },
	 {
	   filename: "./adblockplusandroid-2014-06-01/res/drawable-mdpi/ic_menu_help.png (GPL-3.0)",
	   matches_bin: [
	 		  ["SHA1","100","<a href=\"http:\/\/sourceforge.net\/projects\/entomologist\" target=\"_blank\">sourceforge:entomologist\/git\/source.zip::entomologist-code-44baa9..6f176040c4a52e38cf\/mobile\/Trac\/res\/drawable-mdpi\/ic_menu_help.png<\/a>"],
	 		  ["SHA1","100","<a href=\"https:\/\/code.google.com\/archive\/p\/hs-bremen-guide\/source\/default\/source\" target=\"_blank\">googlecode:hs-bremen-guide\/sourcecode\/hs-bremen-guide-read-only\/HS-Bremen-Guide\/res\/drawable-mdpi\/ic_menu_help.png<\/a>"],
	 		  ["SHA1","100","<a href=\"http:\/\/lampguiden.codeplex.com\/SourceControl\/latest#Main\/Android Source\/res\/drawable-mdpi\/ic_menu_help.png\" target=\"_blank\">codeplex:lampguiden\/lampguiden-40849.zip::Main\/Android Source\/res\/drawable-mdpi\/ic_menu_help.png<\/a>"]
	 		 ]
	 },
	 {
	   filename: "./adblockplusandroid-2014-06-01/res/drawable-mdpi/ic_launcher.png (GPL-3.0)",
	   matches_bin: [
	 		  ["SHA1","100","<a href=\"http:\/\/sourceforge.net\/projects\/adfiltertool\" target=\"_blank\">sourceforge:adfiltertool\/downloads\/AdFilter%20code.zip::AdFilter code\/chrome\/skin\/icon.png<\/a>"],
	 		  ["SHA1","100","<a href=\"https:\/\/github.com\/frozzoman\/adanalysis\/blob\/master\/adblockanalyser\/icon.png\" target=\"_blank\">github:frozzoman\/adanalysis.zip::frozzoman-adanalysis-2e53b8d\/adblockanalyser\/icon.png<\/a>"]
	 		 ]
	 },
	 {
	   filename: "./adblockplusandroid-2014-06-01/res/drawable-mdpi/ic_menu_info_details.png (GPL-3.0)",
	   matches_bin: [
	 		  ["SHA1","100","<a href=\"http:\/\/sourceforge.net\/projects\/androidperiodic\" target=\"_blank\">sourceforge:androidperiodic\/hg\/source.zip::androidperiodic-code-0..cce2f671e9186c86e7f2f6\/res\/drawable-mdpi\/ic_menu_info_details.png<\/a>"],
	 		  ["SHA1","100","<a href=\"https:\/\/code.google.com\/archive\/p\/hs-bremen-guide\/source\/default\/source\" target=\"_blank\">googlecode:hs-bremen-guide\/sourcecode\/hs-bremen-guide-read-only\/HS-Bremen-Guide\/res\/drawable-mdpi\/ic_menu_info_details.png<\/a>"],
	 		  ["SHA1","100","<a href=\"https:\/\/github.com\/flusile\/androvdr\/blob\/master\/res\/drawable-v11\/ic_menu_info_details.png\" target=\"_blank\">github:flusile\/androvdr.zip::flusile-androvdr-91d8d16\/res\/drawable-v11\/ic_menu_info_details.png<\/a>"]
	 		 ]
	 },
	 {
	   filename: "./adblockplusandroid-2014-06-01/res/drawable-mdpi/ic_menu_preferences.png (GPL-3.0)",
	   matches_bin: [
	 		  ["SHA1","100","<a href=\"http:\/\/sourceforge.net\/projects\/androidterm\" target=\"_blank\">sourceforge:androidterm\/downloads\/Android-Terminal-Emulator-maste..nal-Emulator-master\/res\/drawable-mdpi-v11\/ic_menu_preferences.png<\/a>"],
	 		  ["SHA1","100","<a href=\"https:\/\/code.google.com\/archive\/p\/mxpdroid\/source\/default\/source\" target=\"_blank\">googlecode:mxpdroid\/sourcecode\/mxpdroid-read-only\/mXPdroid\/res\/drawable-mdpi\/ic_menu_preferences.png<\/a>"],
	 		  ["SHA1","100","<a href=\"https:\/\/github.com\/fling-mstar\/development\/blob\/master\/samples\/AndroidBeamDemo\/res\/drawable-mdpi\/ic_menu_preferences.png\" target=\"_blank\">github:fling-mstar\/development.zip::fling-mstar-development-f8c2c..samples\/AndroidBeamDemo\/res\/drawable-mdpi\/ic_menu_preferences.png<\/a>"]
	 		 ]
	 },
	 {
	   filename: "./adblockplusandroid-2014-06-01/res/drawable-mdpi/ic_menu_refresh.png (GPL-3.0)",
	   matches_bin: [
	 		  ["SHA1","100","<a href=\"http:\/\/sourceforge.net\/projects\/entomologist\" target=\"_blank\">sourceforge:entomologist\/git\/source.zip::entomologist-code-44baa9..76040c4a52e38cf\/mobile\/Trac\/res\/drawable-mdpi\/ic_menu_refresh.png<\/a>"],
	 		  ["SHA1","100","<a href=\"https:\/\/code.google.com\/archive\/p\/wifi-unlocker\/source\/default\/source\" target=\"_blank\">googlecode:wifi-unlocker\/sourcecode\/wifi-unlocker-read-only\/res\/drawable-mdpi\/ic_menu_refresh.png<\/a>"],
	 		  ["SHA1","100","<a href=\"http:\/\/selvinlistsyncsample.codeplex.com\/SourceControl\/latest#selvinlistsyncsample_5ea4839099e3\/sample\/res\/drawable-mdpi\/ic_menu_refresh.png\" target=\"_blank\">codeplex:selvinlistsyncsample\/selvinlistsyncsample-5ea4839099e3.z..csample_5ea4839099e3\/sample\/res\/drawable-mdpi\/ic_menu_refresh.png<\/a>"]
	 		 ]
	 },
	 {
	   filename: "./adblockplusandroid-2014-06-01/res/drawable-xhdpi/ic_menu_help.png (GPL-3.0)",
	   matches_bin: [
	 		  ["SHA1","100","<a href=\"http:\/\/sourceforge.net\/projects\/mtr-gen\" target=\"_blank\">sourceforge:mtr-gen\/downloads\/sdk.zip::sdk\/platforms\/android-21\/data\/res\/drawable-xhdpi\/ic_menu_help.png<\/a>"],
	 		  ["SHA1","100","<a href=\"https:\/\/code.google.com\/archive\/p\/hs-bremen-guide\/source\/default\/source\" target=\"_blank\">googlecode:hs-bremen-guide\/sourcecode\/hs-bremen-guide-read-only\/HS-Bremen-Guide\/res\/drawable-xhdpi\/ic_menu_help.png<\/a>"],
	 		  ["SHA1","100","<a href=\"http:\/\/lampguiden.codeplex.com\/SourceControl\/latest#Main\/Android Source\/res\/drawable-xhdpi\/ic_menu_help.png\" target=\"_blank\">codeplex:lampguiden\/lampguiden-40849.zip::Main\/Android Source\/res\/drawable-xhdpi\/ic_menu_help.png<\/a>"]
	 		 ]
	 },
	 {
	   filename: "./adblockplusandroid-2014-06-01/res/drawable-xhdpi/ic_menu_info_details.png (GPL-3.0)",
	   matches_bin: [
	 		  ["SHA1","100","<a href=\"http:\/\/sourceforge.net\/projects\/mtr-gen\" target=\"_blank\">sourceforge:mtr-gen\/downloads\/sdk.zip::sdk\/platforms\/android-21\/data\/res\/drawable-xhdpi\/ic_menu_info_details.png<\/a>"],
	 		  ["SHA1","100","<a href=\"https:\/\/code.google.com\/archive\/p\/hs-bremen-guide\/source\/default\/source\" target=\"_blank\">googlecode:hs-bremen-guide\/sourcecode\/hs-bremen-guide-read-only\/HS-Bremen-Guide\/res\/drawable-xhdpi\/ic_menu_info_details.png<\/a>"],
	 		  ["SHA1","100","<a href=\"https:\/\/github.com\/francho\/AOS2012-Android\/blob\/master\/kitaos-android\/res\/drawable-xhdpi\/ic_menu_info_details.png\" target=\"_blank\">github:francho\/AOS2012-Android.zip::francho-AOS2012-Android-219c0b6\/kitaos-android\/res\/drawable-xhdpi\/ic_menu_info_details.png<\/a>"]
	 		 ]
	 },
	 {
	   filename: "./adblockplusandroid-2014-06-01/res/drawable-xhdpi/ic_menu_preferences.png (GPL-3.0)",
	   matches_bin: [
	 		  ["SHA1","100","<a href=\"http:\/\/sourceforge.net\/projects\/androidterm\" target=\"_blank\">sourceforge:androidterm\/downloads\/Android-Terminal-Emulator-maste..al-Emulator-master\/res\/drawable-xhdpi-v11\/ic_menu_preferences.png<\/a>"],
	 		  ["SHA1","100","<a href=\"https:\/\/code.google.com\/archive\/p\/robot-isn\/source\/default\/source\" target=\"_blank\">googlecode:robot-isn\/sourcecode\/robot-isn\/isnBOT\/Code\/res\/drawable\/ic_menu_preferences.png<\/a>"],
	 		  ["SHA1","100","<a href=\"https:\/\/github.com\/fling-mstar\/development\/blob\/master\/samples\/AndroidBeamDemo\/res\/drawable-xhdpi\/ic_menu_preferences.png\" target=\"_blank\">github:fling-mstar\/development.zip::fling-mstar-development-f8c2c..amples\/AndroidBeamDemo\/res\/drawable-xhdpi\/ic_menu_preferences.png<\/a>"]
	 		 ]
	 },
	 {
	   filename: "./adblockplusandroid-2014-06-01/res/drawable-xhdpi/ic_menu_refresh.png (GPL-3.0)",
	   matches_bin: [
	 		  ["SHA1","100","<a href=\"http:\/\/sourceforge.net\/projects\/netpowerctrl\" target=\"_blank\">sourceforge:netpowerctrl\/git\/source.zip::netpowerctrl-code-40d04b..f36a28344edb2a9f599bc35525\/res\/drawable-xhdpi\/ic_menu_refresh.png<\/a>"],
	 		  ["SHA1","100","<a href=\"https:\/\/code.google.com\/archive\/p\/tunesremote-plus\/source\/default\/source\" target=\"_blank\">googlecode:tunesremote-plus\/sourcecode\/tunesremote-plus-read-only\/res\/drawable-xhdpi\/ic_menu_refresh.png<\/a>"],
	 		  ["SHA1","100","<a href=\"https:\/\/github.com\/Fleurer\/fan\/blob\/master\/res\/drawable-xhdpi\/ic_menu_refresh.png\" target=\"_blank\">github:Fleurer\/fan.zip::Fleurer-fan-eb7778e\/res\/drawable-xhdpi\/ic_menu_refresh.png<\/a>"]
	 		 ]
	 },
	 {
	   filename: "./big/build/classes/GUI/disk-black.png",
	   matches_bin: [
	 		  ["SHA1","100","<a href=\"http:\/\/sourceforge.net\/projects\/aqeria\" target=\"_blank\">sourceforge:aqeria\/downloads\/0.5.0.0_dragonfly\/Aqeria\/Resources\/Images\/16x16\/save.png<\/a>"],
	 		  ["SHA1","100","<a href=\"https:\/\/code.google.com\/archive\/p\/big-face-project\/source\/default\/source\" target=\"_blank\">googlecode:big-face-project\/sourcecode\/big-face-project-read-only\/img\/icons\/packs\/fugue\/16x16\/disk-black.png<\/a>"],
	 		  ["SHA1","100","<a href=\"http:\/\/websimplicity.codeplex.com\/SourceControl\/latest#WebSimplicity\/Content\/icons\/disk-black.png\" target=\"_blank\">codeplex:websimplicity\/websimplicity-15166.zip::WebSimplicity\/Content\/icons\/disk-black.png<\/a>"]
	 		 ]
	 },
	 {
	   filename: "./big/src/GUI/disk-black.png",
	   matches_bin: [
	 		  ["SHA1","100","<a href=\"http:\/\/sourceforge.net\/projects\/aqeria\" target=\"_blank\">sourceforge:aqeria\/downloads\/0.5.0.0_dragonfly\/Aqeria\/Resources\/Images\/16x16\/save.png<\/a>"],
	 		  ["SHA1","100","<a href=\"https:\/\/code.google.com\/archive\/p\/big-face-project\/source\/default\/source\" target=\"_blank\">googlecode:big-face-project\/sourcecode\/big-face-project-read-only\/img\/icons\/packs\/fugue\/16x16\/disk-black.png<\/a>"],
	 		  ["SHA1","100","<a href=\"http:\/\/websimplicity.codeplex.com\/SourceControl\/latest#WebSimplicity\/Content\/icons\/disk-black.png\" target=\"_blank\">codeplex:websimplicity\/websimplicity-15166.zip::WebSimplicity\/Content\/icons\/disk-black.png<\/a>"]
	 		 ]
	 }
  ]
 },
 {
  type: "executable",
  files: [
	 {
	   filename: "./big/build/classes/GUI/view$6.class",
	   matches_bin: [
	 		  ["TLSH","78","<a href=\"http:\/\/sourceforge.net\/projects\/brig\" target=\"_blank\">sourceforge:brig\/downloads\/src\/BRIG-0.80-src.zip::BRIG\/build\/classes\/brig\/Two$4.class<\/a>"]
	 		 ]
	 },
	 {
	   filename: "./big/build/classes/GUI/view$7.class",
	   matches_bin: [
	 		  ["TLSH","77","<a href=\"http:\/\/sourceforge.net\/projects\/brig\" target=\"_blank\">sourceforge:brig\/downloads\/src\/BRIG-0.80-src.zip::BRIG\/build\/classes\/brig\/One$11.class<\/a>"],
	 		  ["TLSH","76","<a href=\"http:\/\/sourceforge.net\/projects\/brig\" target=\"_blank\">sourceforge:brig\/downloads\/src\/BRIG-0.80-src.zip::BRIG\/build\/classes\/brig\/One$10.class<\/a>"],
	 		  ["TLSH","75","<a href=\"http:\/\/sourceforge.net\/projects\/brig\" target=\"_blank\">sourceforge:brig\/downloads\/src\/BRIG-0.80-src.zip::BRIG\/build\/classes\/brig\/One$1.class<\/a>"]
	 		 ]
	 }
  ]
 },
 {
  type: "archive",
  files: [
	 {
	   filename: "./big/dist/lib/commons-compress-1.8.1.jar",
	   matches_bin: [
	 		  ["SHA1","100","<a href=\"http:\/\/sourceforge.net\/projects\/geowebcache\" target=\"_blank\">sourceforge:geowebcache\/downloads\/1.8.0-1.8.0-src.zip::geowebcach..\/apache\/commons\/commons-compress\/1.8.1\/commons-compress-1.8.1.jar<\/a>"],
	 		  ["SHA1","100","<a href=\"https:\/\/code.google.com\/archive\/p\/reign-of-defiance\/source\/default\/source\" target=\"_blank\">googlecode:reign-of-defiance\/sourcecode\/reign-of-defiance-read-on..y\/instance\/ReignOfDefianceInvasion\/bin\/commons-compress-1.8.1.jar<\/a>"]
	 		 ]
	 },
	 {
	   filename: "./big/lib/commons-compress-1.8.1/commons-compress-1.8.1-javadoc.jar",
	   matches_bin: [
	 		  ["TLSH","75","<a href=\"https:\/\/code.google.com\/archive\/p\/progressive-learning-platform\/source\/default\/source\" target=\"_blank\">googlecode:progressive-learning-platform\/sourcecode\/progressive-l..PLPTool\/lib\/commons-compress-1.1\/commons-compress-1.1-javadoc.jar<\/a>"]
	 		 ]
	 },
	 {
	   filename: "./big/lib/commons-compress-1.8.1/commons-compress-1.8.1.jar",
	   matches_bin: [
	 		  ["SHA1","100","<a href=\"http:\/\/sourceforge.net\/projects\/geowebcache\" target=\"_blank\">sourceforge:geowebcache\/downloads\/1.8.0-1.8.0-src.zip::geowebcach..\/apache\/commons\/commons-compress\/1.8.1\/commons-compress-1.8.1.jar<\/a>"],
	 		  ["SHA1","100","<a href=\"https:\/\/code.google.com\/archive\/p\/reign-of-defiance\/source\/default\/source\" target=\"_blank\">googlecode:reign-of-defiance\/sourcecode\/reign-of-defiance-read-on..y\/instance\/ReignOfDefianceInvasion\/bin\/commons-compress-1.8.1.jar<\/a>"]
	 		 ]
	 }
  ]
 },
 {
  type: "text",
  files: [
	 {
	   filename: "./big/dist/README.TXT",
	   matches_bin: [
	 		  ["TLSH","96","<a href=\"http:\/\/sourceforge.net\/projects\/abp\" target=\"_blank\">sourceforge:abp\/downloads\/-zip-1.3.zip::README.TXT<\/a>"],
	 		  ["TLSH","94","<a href=\"http:\/\/sourceforge.net\/projects\/accessmysqlwithjava\" target=\"_blank\">sourceforge:accessmysqlwithjava\/svn\/source.zip::accessmysqlwithjava-svn-1\/dist\/README.TXT<\/a>"],
	 		  ["TLSH","83","<a href=\"http:\/\/sourceforge.net\/projects\/acein-iphoto\" target=\"_blank\">sourceforge:acein-iphoto\/downloads\/1.1.9\/aphoto_1.1.9.zip::aphoto_1.1.9\/module\/README.TXT<\/a>"]
	 		 ]
	 },
	 {
	   filename: "./big/lib/commons-compress-1.8.1/LICENSE.txt (Apache-2.0)",
	   matches_bin: [
	 		  ["SHA1","100","<a href=\"http:\/\/sourceforge.net\/projects\/acegi-ext\" target=\"_blank\">sourceforge:acegi-ext\/svn\/source.zip::acegi-ext-code-8-trunk\/acegi-acl-management\/ConfigSource\/license.txt<\/a>"],
	 		  ["SHA1","100","<a href=\"https:\/\/code.google.com\/archive\/p\/ckex-wangjubao\/source\/default\/source\" target=\"_blank\">googlecode:ckex-wangjubao\/sourcecode\/ckex-wangjubao-read-only\/ ck..rc\/test\/java\/org\/apache\/lucene\/demo\/test-files\/docs\/apache2.0.txt<\/a>"],
	 		  ["TLSH","77","maven:maven2\/acegisecurity\/acegi-security\/0.7.0\/acegi-security-0.7.0.jar::META-INF\/license.txt"]
	 		 ]
	 },
	 {
	   filename: "./big/lib/commons-compress-1.8.1/NOTICE.txt",
	   matches_bin: [
	 		  ["SHA1","100","<a href=\"http:\/\/sourceforge.net\/projects\/effy\" target=\"_blank\">sourceforge:effy\/downloads\/1.3.jar::META-INF\/NOTICE.txt<\/a>"],
	 		  ["SHA1","100","<a href=\"https:\/\/github.com\/Flnn\/JavaTools\/blob\/master\/NOTICE.txt\" target=\"_blank\">github:Flnn\/JavaTools.zip::META-INF\/NOTICE.txt<\/a>"],
	 		  ["SHA1","100","bitbucket:wikiforia\/dist\/lib\/commons-compress-1.8.1.jar::META-INF\/NOTICE.txt"]
	 		 ]
	 },
	 {
	   filename: "./big/lib/commons-compress-1.8.1/README.txt",
	   matches_bin: [
	 		  ["SHA1","100","<a href=\"https:\/\/github.com\/Matt529\/ArgusInstaller\/blob\/master\/README.txt\" target=\"_blank\">github:Matt529\/ArgusInstaller.zip::commons-compress-1.8.1-src\/README.txt<\/a>"]
	 		 ]
	 },
	 {
	   filename: "./big/lib/commons-compress-1.8.1/RELEASE-NOTES.txt",
	   matches_bin: [
	 		  ["SHA1","100","<a href=\"https:\/\/github.com\/Matt529\/ArgusInstaller\/blob\/master\/RELEASE-NOTES.txt\" target=\"_blank\">github:Matt529\/ArgusInstaller.zip::commons-compress-1.8.1-src\/RELEASE-NOTES.txt<\/a>"]
	 		 ]
	 }
  ]
 },
 {
  type: "binary",
  files: [
	 {
	   filename: "./adblockplusandroid-2014-06-01/jni/v8/libv8_base.a (GPL-3.0)",
	   matches_bin: [
	 		  ["TLSH","89","bitbucket:robo-js\/android\/libs\/armeabi\/libv8_base.a"]
	 		 ]
	 },
	 {
	   filename: "./adblockplusandroid-2014-06-01/jni/v8/libv8_nosnapshot.a (GPL-3.0)",
	   matches_bin: [
	 		  ["TLSH","89","<a href=\"https:\/\/code.google.com\/archive\/p\/jav8\/source\/default\/source\" target=\"_blank\">googlecode:jav8\/sourcecode\/jav8-read-only\/jni\/armeabi\/libv8_nosnapshot.a<\/a>"]
	 		 ]
	 },
	 {
	   filename: "./adblockplusandroid-2014-06-01/jni/v8/libpreparser_lib.a (GPL-3.0)",
	   matches_bin: [
	 		  ["TLSH","89","<a href=\"https:\/\/code.google.com\/archive\/p\/jav8\/source\/default\/source\" target=\"_blank\">googlecode:jav8\/sourcecode\/jav8-read-only\/jni\/armeabi\/libpreparser_lib.a<\/a>"]
	 		 ]
	 }
  ]
 }
];
