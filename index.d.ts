import { Component } from 'react';
import { ViewStyle } from 'react-native';

export interface ScratchViewProps {
	id?: number;
	brushSize?: number;
	threshold?: number;
	fadeOut?: boolean;
	placeholderColor?: string;
	imageUrl?: string;
	resourceName?: string;
	resizeMode?: 'cover' | 'contain' | 'stretch';
	style?: ViewStyle;
	onImageLoadFinished?: (params: { id?: number; success: boolean }) => void;
	onTouchStateChanged?: (params: { id?: number; touchState: boolean }) => void;
	onScratchProgressChanged?: (params: { id?: number; value: number }) => void;
	onScratchDone?: (params: { id?: number; isScratchDone: boolean }) => void;
}

declare class ScratchView extends Component<ScratchViewProps> {}

export default ScratchView;
