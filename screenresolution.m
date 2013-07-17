/* 
 * screenresolution.m 
 *  
 * Description: 
 *    It set/get current Online display resolutions. 
 * 
 * Author: 
 *    Tony Liu, Copy Right Tony Liu 2011,  All rights reserved. 
 * 
 * Version History: 
 *    2011-06-01: add -a option. 
 *    2011-06-08: Display adding flags and not display duplicate modes. 
 *    2011-06-09: Adding set the best fit resolution function.
 *    2013-07-16: minor error fix.
 *    2013-07-17: add switch Mirror on/off, it support two monitors ONLY.
 * 
 * COMPILE: 
 *    clang screenresolution.m -framework ApplicationServices -o screenresolution -arch i386
 *    gcc screenresolution.m -framework ApplicationServices -o screenresolution -arch i386
 * 
 * screenresolution: set/get current Online display resolutions, set mirror/extend.
 * Copyright (C) 2011  Tony Liu

 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.

 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.

 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>
 */
   
#include <ApplicationServices/ApplicationServices.h>  
struct sLIST {
    double width, height;
	CGDisplayModeRef mode;
};
typedef int (*compfn)(const void*, const void*);
void ListDisplays(uint32_t displayTotal);
void setMirror(bool bOnOff, CGDirectDisplayID display, CGDirectDisplayID main);
void ListDisplayAllMode (CGDirectDisplayID displayID, int index);
void PrintUsage(const char *argv[]);
void PrintModeParms (double width, double height, double depth, double freq, int flag);
int GetModeParms (CGDisplayModeRef mode, double *width, double *height, double *depth, double *freq, int *flag);
int GetDisplayParms(CGDirectDisplayID disp, double *width, double *height, double *depth, double *freq, int *flag);
bool GetBestDisplayMod(CGDirectDisplayID display, double dwidth, double dheight);
int modecompare(struct sLIST *elem1, struct sLIST *elem2);

uint32_t maxDisplays = 20;
CGDirectDisplayID onlineDisplayIDs[20];
uint32_t displayTotal;
char *sysFlags[]={"Unknown","Interlaced,", "Multi-Display,", "Not preset,", "Stretched,"};
char flagString[200];
  
int main (int argc, const char * argv[])  
{
	double width, height, depth, freq;
	int flag;
	int displayNum;
	bool mirrorOn;
	CGDirectDisplayID theDisplay;
	  
	// 1. Getting system info.  
	if (CGGetOnlineDisplayList (maxDisplays, onlineDisplayIDs, &displayTotal) != kCGErrorSuccess) {
		printf("Error on getting online display List.");
		return -1;
	}

	if (argc == 1) {
		CGRect screenFrame = CGDisplayBounds(kCGDirectMainDisplay);
		CGSize screenSize  = screenFrame.size;
		printf("%.0f %.0f\n", screenSize.width, screenSize.height);
		return 0;
	}
	  
	if (! strcmp(argv[1],"-l")) {
		if (argc == 2) {
			ListDisplays(displayTotal);
			return 0;
		}
		else if (argc == 3)  {
			displayNum = atoi(argv[2]);
			if (displayNum <= displayTotal && displayNum > 0) {
				ListDisplayAllMode (onlineDisplayIDs[displayNum-1], 0);
			}
		}
		return 0;
	}
	  
	if (! strcmp(argv[1],"-a")) {
		printf("Total online displays: %d\n", displayTotal);
		return 0;
	}
	  
	if ((! strcmp(argv[1],"-?")) || (! strcmp(argv[1],"-h"))) {
		PrintUsage(argv);
		return 0;
	}
	if (! strcmp(argv[1],"-s")) {
		if (argc == 4) {
			displayNum = 1; width = atoi(argv[2]); height = atoi(argv[3]);
		}
		else if (argc == 5) {
			displayNum = atoi(argv[2]); width = atoi(argv[3]); height = atoi(argv[4]);
		}
		if (displayNum <= displayTotal)  
			flag = GetBestDisplayMod(displayNum-1, width, height);
		return flag;
	}
	if (! strcmp(argv[1], "-m")) {
		mirrorOn = strcmp(argv[2], "off");
		if (maxDisplays > 1) setMirror (mirrorOn, onlineDisplayIDs[1], CGMainDisplayID());
		return 0;
	}
	displayNum = atoi(argv[1]);
	if (displayNum <= displayTotal) {
		GetDisplayParms(onlineDisplayIDs[displayNum-1], &width, &height, &depth, &freq, &flag);
		PrintModeParms (width, height, depth, freq, flag);
		return 0;
	}
	else {
		fprintf(stderr, "ERROR: display number out of bounds; displays on this mac: %d.\n", displayTotal);
		return -1;
	}
	return 0;
}

void setMirror(bool bOnOff, CGDirectDisplayID display, CGDirectDisplayID main)
{
	CGDisplayConfigRef disConfig;
	CGBeginDisplayConfiguration(&disConfig);
	
	if (bOnOff == TRUE) CGConfigureDisplayMirrorOfDisplay(disConfig, display, main);
	else CGConfigureDisplayMirrorOfDisplay(disConfig, display, kCGNullDirectDisplay);
	CGCompleteDisplayConfiguration (disConfig, kCGConfigurePermanently);
}

void ListDisplays(uint32_t displayTotal)  
{
	uint32_t i;
	CGDisplayModeRef mode;
	double width, height, depth, freq;
	int flag;
	  
	// CGDirectDisplayID mainDisplay = CGMainDisplayID();
	printf("Total Online Displays: %d\n", displayTotal);
	for (i = 0 ; i < displayTotal ;i++ ) {
		printf ("  Display %d (id %d): ", i+1, onlineDisplayIDs[i]);
		GetDisplayParms(onlineDisplayIDs[i], &width, &height, &depth, &freq, &flag);
		if ( i == 0 ) printf(" (main) ");
		PrintModeParms (width, height, depth, freq, flag);
	}
}

void ListDisplayAllMode (CGDirectDisplayID displayID, int iNum)  
{
	CFArrayRef modeList;
	CGDisplayModeRef mode;
	CFIndex index, count;
	double width, height, depth, freq;
	int flag;
	double width1, height1, depth1, freq1;
	int flag1;
   
	modeList = CGDisplayCopyAllDisplayModes (displayID, NULL);
	if (modeList == NULL)   return;
	count = CFArrayGetCount (modeList);
	width1=0; height1=0; depth1=0; freq1=0; flag1=0;
	if (iNum <= 0) {
		for (index = 0; index < count; index++)  
		{
			mode = (CGDisplayModeRef)CFArrayGetValueAtIndex (modeList, index);
			GetModeParms(mode, &width, &height, &depth, &freq, &flag);
			PrintModeParms (width, height, depth, freq, flag);
		}
	}
	else if (iNum <= count) {
		mode = (CGDisplayModeRef)CFArrayGetValueAtIndex (modeList, iNum-1);
		GetModeParms(mode, &width, &height, &depth, &freq, &flag);
		PrintModeParms (width, height, depth, freq, flag);
	}
	CFRelease(modeList);
}

void PrintModeParms (double width, double height, double depth, double freq, int flag)  
{
	printf ("%ld x %ld x %ld @ %ld Hz, <%d>\n", (long int)width, (long int)height, (long int)depth, (long int)freq, flag);
}

int GetDisplayParms(CGDirectDisplayID disp, double *width, double *height, double *depth, double *freq, int *flag)  
{
	int iReturn=0;
	CGDisplayModeRef Mode = CGDisplayCopyDisplayMode(disp);
	iReturn = GetModeParms (Mode, width, height, depth, freq, flag);
	CGDisplayModeRelease (Mode);
	return iReturn;
}

int GetModeParms (CGDisplayModeRef Mode, double *width, double *height, double *depth, double *freq, int *sflag)  
{
	*width = CGDisplayModeGetWidth (Mode);
	*height = CGDisplayModeGetHeight (Mode);
	*freq = CGDisplayModeGetRefreshRate (Mode);
	CFStringRef pixelEncoding = CGDisplayModeCopyPixelEncoding (Mode);
	*depth = 0;
	if (pixelEncoding == NULL) return -1;
	if (pixelEncoding == CFSTR(IO32BitDirectPixels))  
		*depth = 32;
	else if (pixelEncoding == CFSTR(IO16BitDirectPixels))  
		*depth = 16;
	else    *depth = 8;
	  
	*sflag = CGDisplayModeGetIOFlags(Mode);
	CFRelease(pixelEncoding);
	return 0;
}

bool GetBestDisplayMod(CGDirectDisplayID display, double dwidth, double dheight)  
{
	CFArrayRef modeList;
	CGDisplayModeRef mode;
	CFIndex index, count, sindex, scount=0;
	double width, height, depth, freq;
	double width1, height1, depth1, freq1;
	int flag, flag1;
	struct sLIST mList[100];
	int ireturn=0;
   
	modeList = CGDisplayCopyAllDisplayModes (display, NULL);
	if (modeList == NULL)   return 1;
	count = CFArrayGetCount (modeList);
	scount=0;
	for (index = 0; index < count; index++)  
	{
		mode = (CGDisplayModeRef)CFArrayGetValueAtIndex (modeList, index);
		GetModeParms(mode, &width, &height, &depth, &freq, &flag);
		// printf("........ scount=%d\n", (int)scount);
		if (!((width==width1) && (height==height1) && (depth==depth1) && (freq==freq1) && (flag==flag1))) {
			if (CGDisplayModeIsUsableForDesktopGUI(mode)) {
				mList[scount].mode=mode; mList[scount].width=width; mList[scount].height=height;
				width1=width; height1=height; depth1=depth; freq1=freq; flag1=flag;
				scount++;
			}
		}
	}
	mode=NULL;
	qsort ((void *) mList, scount, sizeof(struct sLIST), (compfn) modecompare);
	for (index=0; index<scount; index++)
	{
		if (mList[index].width >= dwidth) {
			if (mList[index].height >= dheight) {
				mode = mList[index].mode;
				break;
			}
		}
	}
	  
	CGDisplayConfigRef pConfigRef;
	CGConfigureOption option=kCGConfigurePermanently;
	if ((mode != NULL) && (CGBeginDisplayConfiguration(&pConfigRef) == kCGErrorSuccess)) {
		CGConfigureDisplayWithDisplayMode(pConfigRef, display, mode, NULL);
		if (CGCompleteDisplayConfiguration (pConfigRef, option) !=kCGErrorSuccess) CGCancelDisplayConfiguration (pConfigRef);   
	}
	else ireturn = -1;
	CFRelease(modeList);
	return ireturn;
}

int modecompare(struct sLIST *elem1, struct sLIST *elem2)
{
   if ( elem1->width < elem2->width)  
	  return -1;
   else if (elem1->width > elem2->width) return 1;
   if (elem1->height < elem2->height) return -1;
   else if (elem1->height > elem2->height) return 1;
   else return 0;
}

void PrintUsage(const char *argv[])  
{
	char *fname = strrchr(argv[0], '/')+1;
	printf("Screen Resolution v1.0, Mac OS X 10.6 or later, i386\n");
	printf("Copyright 2010 Tony Liu. All rights reserved. June 1, 2010\n");
	printf("\nUsage:");
	printf("       %s -a\n", fname);
	printf("       %s [-l] [1..9]\n", fname);
	printf("       %s -s [ 1..9 ] hor_res vert_res\n", fname);
	printf("       %s -? | -h     this help.\n\n", fname);
	printf("       %s -m [on | off] set mirror on or off.\n\n", fname);
	printf("      -l  list resolution, depth and refresh rate\n");
	printf("    1..9  display # (default: main display)\n");
	printf("  -l 1-9  List all support for the display #\n");
	printf("      -s  Set mode, see details below.\n");
	printf(" hor_res  horizontal resolution\n");
	printf("vert_res  vertical resolution\n\n");
	printf("Examples:\n");
	printf("%s -a             get online display number\n", fname);
	printf("%s                get current main diplay resolution\n", fname);
	printf("%s 3              get current resolution of third display\n", fname);
	printf("%s -l             get resolution, bit depth and refresh rate of all displays\n", fname);
	printf("%s -l 1           get first display all supported mode\n", fname);
	printf("%s -l 1 2         get first display the second supported mode\n", fname);
	printf("%s -s 800 600     set resolution of main display to 800x600\n", fname);
	printf("%s -s 2 800 600   set resolution of secondary display to 800x600\n", fname);
	printf("%s -m on          turn mirror on\n", fname);
} 
