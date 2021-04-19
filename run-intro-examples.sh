# Set your default paths for Scala 2.11.8 (using Java JDK 1.8), Hadoop 2.7.7 & Spark 2.2.3

export SCALA_HOME=~/scala-2.11.8
export HADOOP_HOME=~/hadoop-2.7.7/
export SPARK_HOME=~/spark-2.2.3-bin-hadoop2.7
export PATH=~/scala-2.11.8/bin:~/hadoop-2.7.7/bin:~/spark-2.2.3-bin-hadoop2.7/bin:$PATH
 
# Download HadoopWordCount.java, HadoopWordStripes.java & HadoopWordPairs.java from Moodle into a new directory called 'HadoopWordCount'.
# Then compile the three Java files per command-line shell:

cd ./HadoopWordCount
javac -classpath $(echo ~/hadoop-2.7.7/share/hadoop/common/*.jar ~/hadoop-2.7.7/share/hadoop/mapreduce/*.jar | tr ' ' ':') *.java
jar -cvf ./HadoopWordCount.jar *.class

# And run the various HadoopWordCount examples on the 'AA' subdirectory from Wikipedia-En-41784-Articles.tar.gz (also available from Moodle):

cd ..
hadoop jar ./HadoopWordCount/HadoopWordCount.jar HadoopWordCount ../Data/enwiki-articles/AA ./hadoop-output1
hadoop jar ./HadoopWordCount/HadoopWordCount.jar HadoopWordPairs ../Data/enwiki-articles/AA ./hadoop-output2
hadoop jar ./HadoopWordCount/HadoopWordCount.jar HadoopWordStripes ../Data/enwiki-articles/AA ./hadoop-output3

# Download SparkWordCount.scala from Moodle into a new directory called 'SparkWordCount'.
# Then compile the single Scala file per command-line shell:

cd ./SparkWordCount
scalac -classpath $(echo ~/spark-2.2.3-bin-hadoop2.7/jars/*.jar | tr ' ' ':') SparkWordCount.scala
jar -cvf ./SparkWordCount.jar *.class

# And submit the SparkWordCount example on the 'AA' subdirectory from Wikipedia-En-41784-Articles.tar.gz (also available from Moodle):

cd ..
spark-submit --class SparkWordCount ./SparkWordCount/SparkWordCount.jar ../Data/enwiki-articles/AA ./spark-output1

# Next perform the same steps also for the SparkTwitterCollector.scala example from Moodle:
# (Make sure to have downloaded the addtional jar files from Moodle into a new directory called 'Jars')

cd ./SparkWordCount
scalac -classpath $(echo ~/spark-2.2.3-bin-hadoop2.7/jars/*.jar ../../Jars/*.jar | tr ' ' ':') SparkTwitterCollector.scala
jar -cvf ./SparkTwitterCollector.jar *.class
cd ..
spark-submit --class SparkTwitterCollector --jars ../Jars/spark-streaming-twitter_2.11-2.2.0.jar,../Jars/twitter4j-stream-4.0.4.jar,../Jars/twitter4j-core-4.0.4.jar ./SparkWordCount/SparkTwitterCollector.jar ./spark-twitter-output 1 10 KVPT7wAENMekaABDEOhiVtuL0 iuNW9UqqWumo0eNj3WmOGoHFmn4owfYwxNtwD44RtMnZ8hL54W 930780178493661184-Wwg5tTtYKyPC6uiahH3rZVQdcuM9BGd PBMIxCAhPNM9qowOIxxvcBf9XyIotELGvPNw8i3zbqn2W 

# Finally open an interactive Spark/Scala shell with some extra driver memory (try out some Scala/Spark examples from the lecture slides):

spark-shell --driver-memory 4G --jars $(echo ../Jars/*.jar | tr ' ' ',')

