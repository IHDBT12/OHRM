package ohrm.util;

import java.io.File;
import java.nio.file.Path;
import java.nio.file.Paths;

import jakarta.servlet.ServletContext;

public final class UploadPathUtils {
    private UploadPathUtils() {
    }

    public static File sourceWebappDirectory(ServletContext context, String webappRelativePath) {
        String realRoot = context.getRealPath("/");
        if (realRoot == null) {
            return null;
        }

        Path deployedRoot = Paths.get(realRoot).normalize();
        String projectName = projectName(context, deployedRoot);
        Path workspaceRoot = workspaceRoot(deployedRoot);
        if (workspaceRoot == null || projectName.isEmpty()) {
            return null;
        }

        String relativePath = webappRelativePath.replace("\\", "/");
        if (relativePath.startsWith("/")) {
            relativePath = relativePath.substring(1);
        }

        return workspaceRoot
            .resolve(projectName)
            .resolve("src")
            .resolve("main")
            .resolve("webapp")
            .resolve(relativePath)
            .toFile();
    }

    private static String projectName(ServletContext context, Path deployedRoot) {
        String contextPath = context.getContextPath();
        if (contextPath != null && contextPath.length() > 1) {
            return contextPath.substring(1);
        }
        Path fileName = deployedRoot.getFileName();
        return fileName == null ? "" : fileName.toString();
    }

    private static Path workspaceRoot(Path deployedRoot) {
        Path current = deployedRoot;
        while (current != null) {
            Path fileName = current.getFileName();
            if (fileName != null && ".metadata".equals(fileName.toString())) {
                return current.getParent();
            }
            current = current.getParent();
        }
        return null;
    }
}
