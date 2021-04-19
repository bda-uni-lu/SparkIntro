import org.apache.spark.mllib.feature.HashingTF
import org.apache.spark.mllib.regression.{LabeledPoint, LinearRegressionWithSGD}             

val spamFile = sc.textFile("../Data/ham-spam/spam.txt")                                
val normalFile = sc.textFile("../Data/ham-spam/ham.txt")

// Map all email text to vectors of 100 features/dimensions               
val tf = new HashingTF(numFeatures = 100)

// Split each email into words, then map each word to one feature          
val spam = spamFile.map(email => tf.transform(email.split(" ")))        
val normal = normalFile.map(email => tf.transform(email.split(" ")))

// Create vectors labeled as spam (1) and as normal (-1) examples.       
val pos = spam.map(features => LabeledPoint(1, features))           
val neg = normal.map(features => LabeledPoint(-1, features))

// Use the union of both as training data                                           
val trainingData = pos.union(neg)                          
trainingData.cache() // SGD is iterative, so cache the training data

// Run Linear Regression using the SGD algorithm                       
val model = new LinearRegressionWithSGD().run(trainingData)

// Test on a positive example (spam) and a negative one (normal).          
val posTest = tf.transform("Viagra GET cheap stuff by sending money to ...".split(" "))
val negTest = tf.transform("Hi Dad, I started studying Spark the other day.".split(" "))

// Finally show the results                                                  
model.predict(posTest)                   
model.predict(negTest)

// Show the learned weights
model.weights

for (i <- "Viagra GET cheap stuff by sending money to ...".split(" ")) {
  println(i + "\t" + tf.indexOf(i) + "\t" + model.predict(tf.transform(List(i))))
}

for (i <- "Hi Dad, I started studying Spark the other day.".split(" ")) {
  println(i + "\t" + tf.indexOf(i) + "\t" + model.predict(tf.transform(List(i))))
}
	

