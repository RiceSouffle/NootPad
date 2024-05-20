plugins {
    alias(libs.plugins.android.application)
}

android {
    namespace = "com.sef.chintaultimate"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.sef.chintaultimate"
        minSdk = 31
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }
}

dependencies {

    implementation(libs.appcompat)
    implementation(libs.material)
    implementation(libs.activity)
    implementation(libs.constraintlayout)
    testImplementation(libs.junit)
    androidTestImplementation(libs.ext.junit)
    androidTestImplementation(libs.espresso.core)

// Room (for database apparently)
    implementation("androidx.room:room-runtime:2.6.1")


    // RecyclerView
    implementation("androidx.recyclerview:recyclerview:1.3.2")


    //Scalable Size Unit (support for different screen sizes)
    implementation("com.intuit.sdp:sdp-android:1.0.6")
    implementation("com.intuit.ssp:ssp-android:1.0.6")

    //Material UI
    implementation("com.google.android.material:material:1.12.0")

    //Rounded ImageView
    implementation("com.makeramen:roundedimageview:2.3.0")




}