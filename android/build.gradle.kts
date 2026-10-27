import com.android.build.api.variant.LibraryAndroidComponentsExtension

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

// Keep file_picker 8's behavior while satisfying its lifecycle plugin's SDK 36
// requirement. finalizeDsl runs after the plugin's hard-coded SDK 34 setting.
// file_picker 13 moved Android into another project, so this applies only when
// the old project is present.
findProject(":file_picker")?.apply {
    plugins.withId("com.android.library") {
        extensions.getByType<LibraryAndroidComponentsExtension>().finalizeDsl {
            it.compileSdk = maxOf(it.compileSdk ?: 0, 36)
        }
    }
}

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
