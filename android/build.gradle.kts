// Kho tải các thư viện Android cho toàn bộ module trong dự án.
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Gom sản phẩm biên dịch về thư mục build ở gốc dự án Flutter.
val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Tác vụ clean xóa sản phẩm biên dịch để có thể dựng lại từ đầu.
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
