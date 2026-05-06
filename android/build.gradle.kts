allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir = rootProject.layout.projectDirectory.dir("../build")
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val projectDir = project.layout.projectDirectory.asFile
    val rootDir = rootProject.layout.projectDirectory.asFile
    if (projectDir.absolutePath.substringBefore(":") == rootDir.absolutePath.substringBefore(":")) {
        project.layout.buildDirectory.value(newBuildDir.dir(project.name))
    }
}
subprojects {
    afterEvaluate {
        if (project.hasProperty("android")) {
            val android = project.extensions.findByName("android")
            if (android is com.android.build.gradle.BaseExtension) {
                if (android.namespace.isNullOrEmpty()) {
                    val manifest = project.file("src/main/AndroidManifest.xml")
                    if (manifest.exists()) {
                        val pkg = javax.xml.parsers.DocumentBuilderFactory.newInstance()
                            .newDocumentBuilder()
                            .parse(manifest)
                            .documentElement
                            .getAttribute("package")
                        if (pkg.isNotEmpty()) {
                            android.namespace = pkg
                        }
                    }
                }
            }
        }
    }
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
